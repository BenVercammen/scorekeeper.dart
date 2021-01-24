import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:test/test.dart';


/// Wrapper class that allows us to keep track of which events have been handled
class _EventHandlerCountWrapper<T extends EventHandler> implements EventHandler {

  final T _eventHandler;

  final Map<AggregateId, Set<DomainEvent>> _handledEvents = HashMap();

  _EventHandlerCountWrapper(this._eventHandler);

  @override
  void handle(Aggregate aggregate, DomainEvent event) {
    _handledEvents.putIfAbsent(aggregate.aggregateId, () => <DomainEvent>{});
    _eventHandler.handle(aggregate, event);
    _handledEvents[aggregate.aggregateId].add(event);
  }

  @override
  Aggregate newInstance(AggregateId aggregateId) {
    return _eventHandler.newInstance(aggregateId);
  }

  @override
  bool handles(DomainEvent event) {
    return _eventHandler.handles(event);
  }

  @override
  bool forType(Type type) {
    return _eventHandler.forType(type);
  }

  int countHandledEvents(AggregateId aggregateId, Type eventType) {
    if (!_handledEvents.containsKey(aggregateId)) {
      return 0;
    }
    return _handledEvents[aggregateId].where((event) => event.payload.runtimeType == eventType).toSet().length;
  }

}


class TracingLogger extends Logger {

  Map<Level, List<String>> loggedMessages = HashMap();

  @override
  void log(Level level, message, [error, StackTrace stackTrace]) {
    super.log(level, message, error, stackTrace);
    loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
    loggedMessages[level].add(message.toString());
  }

}

void main() {

  /// The last thrown exception in a "when" statement
  Exception _lastThrownWhenException;

  TracingLogger _logger;

  const scorableId = 'SCORABLE_ID';

  group('Scorekeeper', () {

    Scorekeeper scorekeeper;

    AggregateCache aggregateCache;

    EventStore eventStore;

    RemoteEventPublisher remoteEventPublisher;

    RemoteEventListener remoteEventListener;

    CommandHandler commandHandler;

    _EventHandlerCountWrapper<ScorableEventHandler> eventHandler;

    setUp(() {
      _logger = TracingLogger();
      eventStore = EventStoreInMemoryImpl(_logger);
      remoteEventPublisher = null; // TODO: RemoteEventPublisher();
      remoteEventListener = null; // TODO: RemoteEventListener();
      aggregateCache = AggregateCacheImpl();
      commandHandler = ScorableCommandHandler();
      eventHandler = _EventHandlerCountWrapper<ScorableEventHandler>(ScorableEventHandler());
      scorekeeper = Scorekeeper(eventStore, aggregateCache, remoteEventPublisher, remoteEventListener, _logger)
        ..registerCommandHandler(commandHandler)
        ..registerEventHandler(eventHandler);
    });


    /// Given we registered for notifications of the aggregate with aggregateId
    void givenAggregateIdRegistered(String aggregateIdValue) {
      final aggregateId = AggregateId.of(aggregateIdValue);
      scorekeeper.registerAggregate(aggregateId, Scorable);
    }

    /// Given we did not register for notifications of the aggregate with aggregateId
    void givenAggregateIdNotRegistered(String aggregateIdValue) {
      final aggregateId = AggregateId.of(aggregateIdValue);
      scorekeeper.unregisterAggregate(aggregateId);
    }

    /// Given the aggregate with Id should be cached by the Scorekeeper
    void givenAggregateIdCached(String aggregateId) {
      scorekeeper.addAggregateToCache(AggregateId.of(aggregateId), Scorable);
    }

    /// Given the aggregate with Id is not cached by the Scorekeeper
    void givenAggregateIdEvictedFromCache(String aggregateId) {
      scorekeeper.evictAggregateFromCache(AggregateId.of(aggregateId));
    }

    /// Given the ScorableCreatedEvent with parameters
    void givenScorableCreatedEvent(String aggregateIdValue, String name, [DomainEventId eventId]) {
      final scorableCreated = ScorableCreated()
        ..aggregateId = aggregateIdValue
        ..name = name;
      // Store and publish
      final aggregateId = AggregateId.of(aggregateIdValue);
      final sequence = eventStore.countEventsForAggregate(aggregateId) + 1;
      eventStore.store(DomainEvent.of(eventId??DomainEventId.local(sequence), aggregateId, scorableCreated));
    }

    /// Given the ParticipantAdded event
    void givenParticipantAddedEvent(String aggregateIdValue, String participantId, String participantName, [DomainEventId eventId]) {
      final participantAdded = ParticipantAdded()
        ..aggregateId = aggregateIdValue;
      final participant = Participant()
        ..participantId = participantId
        ..name = participantName;
      participantAdded.participant = participant;
      // Store and publish
      final aggregateId = AggregateId.of(aggregateIdValue);
      final sequence = eventStore.countEventsForAggregate(aggregateId) + 1;
      eventStore.store(DomainEvent.of(eventId??DomainEventId.local(sequence), aggregateId, participantAdded));
    }

    /// Given no aggregate with given Id is known in Scorekeeper
    void givenNoAggregateKnownWithId(String aggregateIdValue) {
      final aggregateId = AggregateId.of(aggregateIdValue);
      aggregateCache.purge(aggregateId);
    }

    void givenCacheIsUpToDate(String aggregateIdValue) {
      scorekeeper.refreshCache(Scorable, AggregateId.of(aggregateIdValue));
    }

    void when(Function() callback) {
      try {
        _lastThrownWhenException = null;
        callback();
      } on Exception catch (exception) {
        _lastThrownWhenException = exception;
      }
    }

    /// When the given command is sent to Scorekeeper
    void command(dynamic command) {
      scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    void createScorableCommand(String aggregateId, String name) {
      final command = CreateScorable()
        ..aggregateId = aggregateId
        ..name = name;
      scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    void addParticipantCommand(String aggregateId, String participantId, String participantName) {
      final command = AddParticipant()
        ..aggregateId = aggregateId
        ..participant = Participant()
        ..participant.participantId = participantId
        ..participant.name = participantName;
      scorekeeper.handleCommand(command);
    }

    /// When an aggregate with given Id is evicted from cache
    void evictAggregateFromCache(String aggregateId) {
      scorekeeper.evictAggregateFromCache(AggregateId.of(aggregateId));
    }

    /// When an aggregate should be loaded
    Scorable loadAggregateFromCache(String aggregateId) {
      return scorekeeper.getCachedAggregateById(AggregateId.of(aggregateId));
    }

    /// Eventually means asynchronously, so we'll just wait a few millis to check
    Future<void> eventually(Function() callback) async {
      await Future.delayed(const Duration(milliseconds: 10));
      callback();
    }

    /// Then the cached aggregate should ...
    void thenAssertCachedState<T extends Aggregate>(String aggregateId, Function(T aggregate) callback) {
      final aggregate = aggregateCache.get<T>(AggregateId.of(aggregateId));
      callback(aggregate);
    }

    /// Then the aggregate with given Id should be cached
    void thenAggregateShouldBeCached(String aggregateId) {
      expect(aggregateCache.contains(AggregateId.of(aggregateId)), equals(true));
    }

    /// Then the aggregate with given Id should not be cached
    void thenAggregateShouldNotBeCached(String aggregateId) {
      expect(aggregateCache.contains(AggregateId.of(aggregateId)), equals(false));
    }

    /// Then the aggregate with given Id should not be registered
    void thenAggregateShouldNotBeRegistered(String aggregateId) {
      expect(scorekeeper.isRegistered(AggregateId.of(aggregateId)), equals(false));
    }

    /// Then the aggregate with given Id should be registered
    void thenAggregateShouldBeRegistered(String aggregateId) {
      expect(scorekeeper.isRegistered(AggregateId.of(aggregateId)), equals(true));
    }

    /// Then the event with payload of given type should be stored exactly [numberOfTimes] times for aggregate with Id
    void thenEventTypeShouldBeStoredNumberOfTimes(String aggregateId, Type eventType, int numberOfTimes) {
      final eventsForAggregate = eventStore.getEventsForAggregate(AggregateId.of(aggregateId));
      final equalEventPayloads = Set<DomainEvent>.from(eventsForAggregate)
        ..retainWhere((event) => event.payload.runtimeType == eventType);
      expect(equalEventPayloads.length, equals(numberOfTimes));
    }

    /// Then the event with payload of given type should actually be handled exactly [numberOfTimes] for the aggregate with Id
    void thenEventTypeShouldBeHandledNumberOfTimes(String aggregateId, Type eventtype, int numberOfTimes) {
      expect(eventHandler.countHandledEvents(AggregateId.of(aggregateId), eventtype), equals(numberOfTimes));
    }

    /// Then the given Exception should have been thrown
    void thenExceptionShouldBeThrown(Exception expected) {
      expect(_lastThrownWhenException, isNotNull);
      expect(_lastThrownWhenException.toString(), equals(expected.toString()));
    }

    /// Then the given message should be logged number of times
    void thenMessageShouldBeLoggedNumberOfTimes(Level level, String expectedMessage, int times) {
      _logger.loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
      expect(_logger.loggedMessages[level].where((loggedMessage) => loggedMessage.contains(expectedMessage)).length, equals(times));
    }

    /// Then the given message should not be logged
    void thenNoMessageShouldBeLogged(Level level, String expectedMessage, int times) {
      thenMessageShouldBeLoggedNumberOfTimes(level, expectedMessage, 0);
    }

    /// Then a SystemEvent of the given type should be published
    void thenSystemEventShouldBePublished(SystemEvent expectedEvent) {
      expect(eventStore.getSystemEvents().where((actualEvent) {
        if (actualEvent.runtimeType != expectedEvent.runtimeType) {
          return false;
        }
        if (actualEvent is EventNotHandled && expectedEvent is EventNotHandled) {
          return actualEvent.notHandledEventId == expectedEvent.notHandledEventId &&
                  actualEvent.reason == expectedEvent.reason;
        }
        return false;
      }).length, equals(1));
    }


    group('Test creation and initial usage of the Scorekeeper instance', () {

      test('Constructor requires local EventStore', () {
        try {
          Scorekeeper(null, AggregateCacheImpl(), null, null);
          fail('Instantiating without local EventStore instance should fail');
        } on Exception catch (exception) {
          expect(exception.toString(), contains('Local EventStore instance is required'));
        }
      });

      test('Constructor requires an AggregateCache', () {
        try {
          Scorekeeper(EventStoreInMemoryImpl(_logger), null, null, null);
          fail('Instantiating without AggregateCache instance should fail');
        } on Exception catch (exception) {
          expect(exception.toString(), contains('AggregateCache instance is required'));
        }
      });


      group('Scorekeeper without handlers', () {

        Scorekeeper scorekeeper;

        setUp(() {
          scorekeeper = Scorekeeper(EventStoreInMemoryImpl(_logger), AggregateCacheImpl(), null, null);
        });

        /// Commands that can't be handled, should raise an exception
        test('Command without handler', () {
          try {
            scorekeeper.handleCommand(CreateScorable()
              ..name = 'Test'
              ..aggregateId = AggregateId
                  .random()
                  .id);
            fail('Expected exception because of missing command handler(s)');
          } on Exception catch (exception) {
            expect(exception.toString(), contains("No command handler registered for Instance of 'CreateScorable'"));
          }
        });

        // We don't allow for explicitly handling events in the scorekeeper application, only commands...
        // /// Events that aren't handled, won't raise any exceptions (for now)
        // test('Event without handler', () {
        //   scorekeeper.handleEvent(DomainEvent.of(DomainEventId.local(0), AggregateId.random(), CreateScorable()));
        // });
      });

      group('Register/unregister aggregates', () {

        /// When unregistering an aggregate, we also want to remove all events from the local event manager
        /// We're no longer interested in the aggregate, and don't care if anyone else is...
        test('Test unregister aggregate', () {
          final aggregateId = AggregateId.random();
          scorekeeper.registerAggregate(aggregateId, Scorable);
          givenScorableCreatedEvent(aggregateId.id, 'Test');
          thenAggregateShouldBeRegistered(aggregateId.id);
          thenEventTypeShouldBeStoredNumberOfTimes(aggregateId.id, ScorableCreated, 1);
          // unregister
          scorekeeper.unregisterAggregate(aggregateId);
          thenAggregateShouldNotBeRegistered(aggregateId.id);
          thenEventTypeShouldBeStoredNumberOfTimes(aggregateId.id, ScorableCreated, 0);
        });
      });

    });


    ///
    /// Vocabulary
    ///
    ///  - Registered AggregateIds: Events are only stored in the (local) EventStore
    ///                             if the aggregateId is registered within the EventStore
    ///  - Cached AggregateIds:     aggregates that are fully hydrated within the AggregateCache
    ///  - Non-cached AggregateIds: aggregates for which only the events are stored.
    ///                             When loading, these aggregates need to be re-hydrated based on the stored events
    ///
    ///  - Constructor event: initializing event triggered by the constructor command
    ///


    /// Tests regarding event handling
    /// Events should raise some sort of ExceptionEvent in case something went wrong
    /// Event handling should never (or very rarely) result in actual exceptions
    /// TODO: So we'll have some sort of EventHandlingException log??
    group('Event handling', () {

      group('Constructor events', () {

        test('Handle constructor event for registered, non-cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldNotBeCached(scorableId);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        /// For a non-registered aggregateId, the constructor event should not even be stored in the local event manager
        /// We presume that we'll get notified in time whenever a new aggregate that's relevant to us will be created,
        /// so we can register that specific aggregate.
        /// What we want to prevent is that we'll start pulling in ALL aggregates that are being created,
        /// even though we'll never make use of them
        test('Handle constructor event for unregistered aggregateId', () async {
          givenAggregateIdNotRegistered(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0);
          thenAggregateShouldNotBeCached(scorableId);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        test('Handle constructor event for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
        });

        /// When a new constructor event tries to create an aggregate for an already existing aggregateId,
        /// the system should ignore this event and raise a new SystemEvent
        /// TODO: this is actually a test for the scorekeeper now...
        test('Handle constructor event for already existing registered, cached aggregateId', () async {
          final eventId1 = DomainEventId.local(0);
          final eventId2 = DomainEventId.local(0);
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1', eventId1);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
          givenScorableCreatedEvent(scorableId, 'TEST 1', eventId2);
          await eventually(() {
            final eventNotHandled = EventNotHandled(eventId2, 'Sequence invalid');
            thenSystemEventShouldBePublished(eventNotHandled);
          });
        });

        // TODO: only not-yet-handled events should get handled... (so look at EventId!)
        //  but that's probably more of the EventStore's concern/responsibility??


        /// TODO: what if a constructor event tries to create an already created aggregateId
        ///  this could pop up when the RemoteEventManager sends us an event..
        ///  Do we generate some kind of SystemEvent and ignore the actual Event?
        ///  Just pass the bucket on and handle this situation when it actually arises?

      });

      group('Regular events', () {

        test('Handle regular event for registered, non-cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
          when(() => evictAggregateFromCache(scorableId));
          thenAggregateShouldNotBeCached(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          givenParticipantAddedEvent(scorableId, 'PARTICIPANT_ID', 'Player One');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ParticipantAdded, 1));
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        /// After an AggregateId has been evicted from cache, it should no longer be cached
        test('Handle regular event for registered, evicted-from-cache aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldBeCached(scorableId);
          when(() => evictAggregateFromCache(scorableId));
          thenAggregateShouldNotBeCached(scorableId);
          givenParticipantAddedEvent(scorableId, 'PARTICIPANT_ID', 'Player One');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ParticipantAdded, 1);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        test('Handle regular event for unregistered, non-cached aggregateId', () {
          givenAggregateIdNotRegistered(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1');
          thenAggregateShouldNotBeRegistered(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0);
        });

        test('Handle regular event for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test 1');
          givenParticipantAddedEvent(scorableId, 'PARTICIPANT_ID', 'Player One');
          // TODO: dus ook scenario's schrijven waarin cache out-of-date is? of zou da nooit mogen?
          givenCacheIsUpToDate(scorableId);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ParticipantAdded, 1);
          // Cached state should reflect the handled event...
          thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
            expect(scorable.name, equals('Test 1'));
            expect(scorable.participants.length, equals(1));
          });
        });

        test('Handle regular event for unregistered aggregateId', () {
          givenAggregateIdNotRegistered(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test');
          thenAggregateShouldNotBeCached(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0);
        });

      });

      // TODO: als we cache opzetten, moet ook ineens de volledig gehydrateerde aggregate in cache zitten!
      //  dus alle events moeten applied zijn!

    });

    /// Tests regarding command handling
    /// Commands should throw Exceptions as they are (currently) always handled synchronously.
    /// We want to give feedback to the issuer as fast as possible.
    /// Only if the consistency boundry surpasses that of the affected Aggregate (so when multiple Aggregates are affected),
    /// any exceptions would probably be represented by "exception events", but that is saga-territory (I think).
    group('Command handling', () {

      /// TODO: Non-constructor commands can only be handled on aggregates that are registered??

      group('Constrctor commands', () {

        /// A Constructor Command should result in a newly created, registered and cached Aggregate
        /// We want this in cache because the high probability of extra commands following the initial one
        test('Handle constructor command for non-existing unregistered, non-cached aggregateId', () {
          givenNoAggregateKnownWithId(scorableId);
          givenAggregateIdEvictedFromCache(scorableId);
          when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(scorableId);
          thenAggregateShouldBeRegistered(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          // Check cached values (this is actually testing the domain itself, so not really something we need to do here)
          thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
            expect(scorable, isNotNull);
            expect(scorable.aggregateId, equals(AggregateId.of(scorableId)));
            expect(scorable.name, equals('Test Scorable 1'));
          });
        });

        test('Handle constructor command for non-existing registered, non-cached aggregateId', () {
          givenNoAggregateKnownWithId(scorableId);
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdEvictedFromCache(scorableId);
          when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(scorableId);
        });

        test('Handle constructor command for non-existing registered, cached aggregateId', () {
          givenNoAggregateKnownWithId(scorableId);
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(scorableId);
        });

        test('Handle constructor command for non-existing unregistered, cached aggregateId', () {
          givenNoAggregateKnownWithId(scorableId);
          givenAggregateIdNotRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(scorableId);
          thenAggregateShouldBeRegistered(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
        });

        /// Scorekeeper should block new constructor commands for already existing aggregates
        test('Handle constructor command for already existing registered, cached aggregateId', () {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable 1');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
          thenExceptionShouldBeThrown(AggregateIdAlreadyExistsException(AggregateId.of(scorableId)));
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldBeCached(scorableId);
          thenAggregateShouldBeRegistered(scorableId);
        });

        /// Handling a command should not result in the same event being triggered/handled twice
        test('Handling constructor command should emit event(s) only once', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable 1');
          await eventually(() => thenNoMessageShouldBeLogged(Level.info, 'Received and ignored duplicate Event', 0));
        });

      });

      group('Regular commands', () {

        test('Handle regular command for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable');
          givenCacheIsUpToDate(scorableId);
          when(() => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'));
          thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ScorableCreated, 1);
          thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ParticipantAdded, 1);
          thenAggregateShouldBeCached(scorableId);
          // Check if Participant is actually added
          thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
            expect(scorable.participants, isNotNull);
            expect(scorable.participants.length, equals(1));
          });
        });

        test('Handle regular command for unregistered, non-cached aggregateId', () async {
          givenAggregateIdNotRegistered(scorableId);
          givenAggregateIdEvictedFromCache(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0));
        });

        test('Command should always have an aggregateId value', () {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable');
          final invalidCommand = AddParticipant()
            ..aggregateId = null;
          when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand));
        });

        test('Command should always have an aggregateId property', () {
          final invalidCommand = Object();
          when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand));
        });

        test('No command handler found', () {
          scorekeeper.unregisterCommandHandler(commandHandler);
          final unsupportedCommand = CreateScorable()
            ..aggregateId = AggregateId.random().id;
          when(() => command(unsupportedCommand));
          thenExceptionShouldBeThrown(UnsupportedCommandException(unsupportedCommand));
        });

        test('Multiple command handlers found', () {
          final extraCommandHandler = ScorableCommandHandler();
          scorekeeper.registerCommandHandler(extraCommandHandler);
          final duplicateCommand = CreateScorable()
            ..aggregateId = AggregateId.random().id;
          when(() => command(duplicateCommand));
          thenExceptionShouldBeThrown(MultipleCommandHandlersException(duplicateCommand));
        });

        /// We had an issue where the events emitted by regular commands would be handled twice.
        /// The tricky part is that the second handled event was handled asynchronously,
        /// so if we don't wait for it in our tests, we'd never notice it...
        /// This test will explicitly wait to make sure that something like that doesn't happen (again).
        test('Regular command should have its emitted events applied only once', () async {
          when(() => createScorableCommand(scorableId, 'Test'));
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1));
          await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ScorableCreated, 1));
          when(() => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'));
          thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ScorableCreated, 1);
          thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ParticipantAdded, 1);
          thenAggregateShouldBeCached(scorableId);
          // Check if Participant is actually added
          await eventually(() => thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
            expect(scorable.participants, isNotNull);
            expect(scorable.participants.length, equals(1));
          }));
        });

      });
      /// TODO: regular command for not yet registered aggregate should fail, OR retrieve from remote..
      /// if we don't yet have a constructor event for the aggregate, then we're pretty much fucked...

      /// TODO: testen dat command handler effectief alle "applied events" van de aggregate afhaalt?
      ///  -> zijn er scenario's waarin er events verloren kunnen gaan?
      ///  -> dan zou command handler moeten falen!
      ///       -> als er niemand het command afhandelt, moet de issue'er van het command dit weten!

      /// TODO: wat met de flow waarin command handler met een lege aggregate achterblijft?

    });

  });

}


