import 'dart:collection';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'features/step_definitions.dart';


/// Wrapper class that allows us to keep track of which events have been handled
class _EventHandlerCountWrapper<T extends EventHandler> implements EventHandler {

  final T _eventHandler;

  final Map<AggregateId, Set<DomainEvent>> _handledEvents = HashMap();

  Function(Aggregate aggregate, DomainEvent domainEvent)? _handlerInterceptor;

  _EventHandlerCountWrapper(this._eventHandler);

  @override
  void handle(Aggregate aggregate, DomainEvent event) {
    _handledEvents.putIfAbsent(aggregate.aggregateId, () => <DomainEvent>{});
    if (null == _handlerInterceptor) {
      _eventHandler.handle(aggregate, event);
    } else {
      _handlerInterceptor!(aggregate, event);
    }
    _handledEvents[aggregate.aggregateId]!.add(event);
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
    return _handledEvents[aggregateId]!.where((event) => event.payload.runtimeType == eventType).toSet().length;
  }

  void addHandlerInterceptor(Function(Aggregate aggregate, DomainEvent event) interceptor) {
    this._handlerInterceptor = interceptor;
  }

}

/// Wrapper class that allows us to keep track of which commands have been sent/received/handled
class _CommandHandlerWrapper<T extends CommandHandler> implements CommandHandler {

  final T _commandHandler;

  Function(String beforeAfter, Aggregate aggregate, dynamic command)? _handlerInterceptor;

  _CommandHandlerWrapper(this._commandHandler);

  @override
  void handle(Aggregate aggregate, command) {
    if (null != _handlerInterceptor) {
      _handlerInterceptor!("BEFORE", aggregate, command);
    }
    _commandHandler.handle(aggregate, command);
    if (null != _handlerInterceptor) {
      _handlerInterceptor!("AFTER", aggregate, command);
    }
  }

  @override
  Aggregate handleConstructorCommand(command) {
    var aggregate = _commandHandler.handleConstructorCommand(command);
    return aggregate;
  }

  @override
  bool handles(command) {
    return _commandHandler.handles(command);
  }

  @override
  bool isConstructorCommand(command) {
    return _commandHandler.isConstructorCommand(command);
  }

  @override
  Aggregate newInstance(AggregateId aggregateId) {
    return _commandHandler.newInstance(aggregateId);
  }

  /// Extra callback method to be called before actually handling the method.
  /// This allows us to add some "magic" to the command handlers which might be useful for testing.
  void addHandlerInterceptor(void Function(String beforeAfter, Aggregate aggregate, dynamic command) interceptor) {
    _handlerInterceptor = interceptor;
  }

}


class TracingLogger extends Logger {

  final Map<Level, List<String>> loggedMessages = HashMap();

  @override
  void log(Level level, message, [error, StackTrace? stackTrace]) {
    super.log(level, message, error, stackTrace);
    loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
    loggedMessages[level]?.add(message.toString());
  }

}

void main() {

  /// The last thrown exception in a "when" statement
  late Exception? _lastThrownWhenException;

  late TracingLogger _logger;

  const scorableId = 'SCORABLE_ID';

  group('Scorekeeper', () {

    late Scorekeeper scorekeeper;

    late DomainEventFactory domainEventFactory;

    late AggregateCache aggregateCache;

    late EventStore eventStore;

    late MockRemoteEventPublisher remoteEventPublisher;

    late MockRemoteEventListener remoteEventListener;

    late _CommandHandlerWrapper<ScorableCommandHandler> commandHandler;

    late _EventHandlerCountWrapper<ScorableEventHandler> eventHandler;

    setUp(() {
      _logger = TracingLogger();
      eventStore = EventStoreInMemoryImpl(_logger);
      domainEventFactory = DomainEventFactory(producerId: 'localtestmachine', applicationVersion: 'TODO-appversion');
      remoteEventPublisher = MockRemoteEventPublisher();
      remoteEventListener = MockRemoteEventListener();
      aggregateCache = AggregateCacheInMemoryImpl();
      commandHandler = _CommandHandlerWrapper<ScorableCommandHandler>(ScorableCommandHandler());
      eventHandler = _EventHandlerCountWrapper<ScorableEventHandler>(ScorableEventHandler());
      scorekeeper = Scorekeeper(
          eventStore: eventStore,
          aggregateCache: aggregateCache,
          domainEventFactory: domainEventFactory,
          remoteEventPublisher: remoteEventPublisher,
          remoteEventListener: remoteEventListener,
          logger: _logger)
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
    Future<void> givenAggregateIdCached(String aggregateId) async {
      await scorekeeper.loadAndAddAggregateToCache(AggregateId.of(aggregateId), Scorable);
    }

    /// Given the aggregate with Id is not cached by the Scorekeeper
    void givenAggregateIdEvictedFromCache(String aggregateId) {
      scorekeeper.evictAggregateFromCache(AggregateId.of(aggregateId));
    }

    /// Given the DomainEvent is already persisted locally
    void givenLocallyPersistedEvent(DomainEvent domainEvent) {
      eventStore.storeDomainEvent(domainEvent);
    }

    /// Given the ScorableCreatedEvent with parameters
    void givenScorableCreatedEvent(String aggregateIdValue, String name, [int? sequence, String? eventId]) {
      final scorableCreated = ScorableCreated()
        ..aggregateId = aggregateIdValue
        ..name = name;
      // Store and publish
      final aggregateId = AggregateId.of(aggregateIdValue);
      eventId ??= Uuid().v4().toString();
      sequence ??= eventStore.countEventsForAggregate(aggregateId) + 1;
      final event = domainEventFactory.remote(eventId, aggregateId, sequence, DateTime.now(), scorableCreated);
      eventStore.storeDomainEvent(event);
    }

    /// Given the ParticipantAdded event
    void givenParticipantAddedEvent(String aggregateIdValue, String participantId, String participantName, [String? eventId]) {
      final participantAdded = ParticipantAdded()
        ..aggregateId = aggregateIdValue;
      final participant = Participant(participantId, participantName);
      participantAdded.participant = participant;
      // Store and publish
      final aggregateId = AggregateId.of(aggregateIdValue);
      final sequence = eventStore.countEventsForAggregate(aggregateId) + 1;
      final event = domainEventFactory.local(aggregateId, sequence, participantAdded);
      eventStore.storeDomainEvent(event);
    }

    /// Given no aggregate with given Id is known in Scorekeeper
    void givenNoAggregateKnownWithId(String aggregateIdValue) {
      final aggregateId = AggregateId.of(aggregateIdValue);
      aggregateCache.purge(aggregateId);
    }

    void givenCacheIsUpToDate(String aggregateIdValue) {
      scorekeeper.refreshCache(Scorable, AggregateId.of(aggregateIdValue));
    }

    Future<void> when(Function() callback) async {
      try {
        _lastThrownWhenException = null;
        await callback();
      } on Exception catch (exception) {
        _lastThrownWhenException = exception;
      }
    }

    /// Asynchronously run 2 callbacks without waiting on the results...
    Future<void> whenSimultaneously(Function() callback1, Function() callback2) async {
      try {
        _lastThrownWhenException = null;
        callback1();
        callback2();
      } on Exception catch (exception) {
        _lastThrownWhenException = exception;
      }
    }

    /// When the given command is sent to Scorekeeper
    void command(dynamic command) {
      scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    Future<void> createScorableCommand(String aggregateId, String name) async {
      final command = CreateScorable()
        ..aggregateId = aggregateId
        ..name = name;
      scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    Future<void> addParticipantCommand(String aggregateId, String participantId, String participantName) async {
      final command = AddParticipant()
        ..aggregateId = aggregateId
        ..participant = Participant(participantId, participantName);
      scorekeeper.handleCommand(command);
    }

    /// When the RemoteEventListener receives a new DomainEvent
    Future<void> receivedRemoteEvent(DomainEvent domainEvent) async {
      remoteEventListener.emitEvent(domainEvent);
    }

    /// When an aggregate with given Id is evicted from cache
    void evictAggregateFromCache(String aggregateId) {
      scorekeeper.evictAggregateFromCache(AggregateId.of(aggregateId));
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
    Future<void> thenEventTypeShouldBeStoredNumberOfTimes(String aggregateId, Type eventType, int numberOfTimes) async {
      final eventsForAggregate = eventStore.getDomainEvents(aggregateId: AggregateId.of(aggregateId));
      final equalEventPayloads = await eventsForAggregate.where((event) => event.payload.runtimeType == eventType).toSet();
      expect(equalEventPayloads.length, equals(numberOfTimes));
    }

    /// Then the event with payload of given type should actually be handled exactly [numberOfTimes] for the aggregate with Id
    void thenEventTypeShouldBeHandledNumberOfTimes(String aggregateId, Type eventType, int numberOfTimes) {
      expect(eventHandler.countHandledEvents(AggregateId.of(aggregateId), eventType), equals(numberOfTimes));
    }

    /// Then the event with payload of given type should be published exactly [numberOfTimes] for the aggregate with Id
    void thenEventTypeShouldBePublishedNumberOfTimes(String aggregateId, Type eventType, int numberOfTimes) {
      final matches = remoteEventPublisher.publishedDomainEvents.where((publishedEvent) {
        return publishedEvent.aggregateId.id == aggregateId && publishedEvent.payload.runtimeType == eventType;
      });
      expect(matches.length, equals(numberOfTimes));
    }

    /// Then no events should be published
    void thenNoEventsShouldBePublishedForAggregateId(String aggregateId) {
      final matches = remoteEventPublisher.publishedDomainEvents.where((publishedEvent) {
        return publishedEvent.aggregateId.id == aggregateId;
      });
      expect(matches, isEmpty);
    }

    /// Then the given Exception should have been thrown
    void thenExceptionShouldBeThrown(Exception expected) {
      expect(_lastThrownWhenException, isNotNull);
      expect(_lastThrownWhenException.toString(), equals(expected.toString()));
    }

    /// Then no Exception should have been thrown
    void thenNoExceptionShouldBeThrown() {
      expect(_lastThrownWhenException, isNull);
    }

    /// Then the given message should be logged number of times
    void thenMessageShouldBeLoggedNumberOfTimes(Level level, String expectedMessage, int times) {
      _logger.loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
      expect(_logger.loggedMessages[level]!.where((loggedMessage) => loggedMessage.contains(expectedMessage)).length, equals(times));
    }

    /// Then the given message should not be logged
    void thenNoMessageShouldBeLogged(Level level, String expectedMessage, int times) {
      thenMessageShouldBeLoggedNumberOfTimes(level, expectedMessage, 0);
    }

    /// Then a SystemEvent of the given type should be published
    Future<void> thenSystemEventShouldBePublished(SystemEvent expectedEvent) async {
      var systemEvents = eventStore.getSystemEvents().where((actualEvent) {
        if (actualEvent.runtimeType != expectedEvent.runtimeType) {
          return false;
        }
        if (actualEvent is EventNotHandled && expectedEvent is EventNotHandled) {
          return actualEvent.notHandledEvent.eventId == expectedEvent.notHandledEvent.eventId &&
              actualEvent.reason.contains(expectedEvent.reason);
        }
        return false;
      });
      final actualEvents = await systemEvents.toList();
      expect(actualEvents.length, equals(1));
    }

    /// Then no SystemEvent should be published
    Future<void> thenNoSystemEventShouldBePublished() async {
      expect(await eventStore.getSystemEvents().toSet(), isEmpty);
    }

    group('Test creation and initial usage of the Scorekeeper instance', () {

      group('Scorekeeper without handlers', () {

        late Scorekeeper scorekeeper;

        setUp(() {
          scorekeeper = Scorekeeper(eventStore: EventStoreInMemoryImpl(_logger),
              domainEventFactory: domainEventFactory,
              aggregateCache: AggregateCacheInMemoryImpl());
        });

        /// Commands that can't be handled, should raise an exception
        test('Command without handler', () async {
          try {
            await scorekeeper.handleCommand(CreateScorable()
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
        test('Test unregister aggregate', () async {
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


    /// Tests regarding the handling of remotely received events
    /// Events should raise some sort of ExceptionEvent in case something went wrong
    /// Event handling should never (or very rarely) result in actual exceptions
    /// TODO: So we'll have some sort of EventHandlingException log??
    ///
    /// - TODO: Scenario: Remote event cannot be stored for whatever reason -> event should NOT be applied locally
    /// - TODO: Scenario: Remote event can be stored, but not applied: ... REMOVE event from repository?? (store + state should be in sync)
    /// If an event cannot be stored or applied: store it in a separate repository???
    ///
    group('Event handling', () {

      group('Constructor events', () {

        /// Not sure how we can register the aggregateId for a remotely created aggregate... :/
        /// TODO: we'll have to device a way to receive events from related aggregates, and then register and pull events "manually"
        test('Handle constructor event for registered, non-cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          final payload = ScorableCreated()
            ..aggregateId = scorableId
            ..name = 'Test';
          await when(() => receivedRemoteEvent(
            domainEventFactory.local(AggregateId.of(scorableId), 0, payload)));
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldNotBeCached(scorableId);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
          thenNoEventsShouldBePublishedForAggregateId(scorableId);
        });

        /// For a non-registered aggregateId, the constructor event should not even be stored in the local event manager
        /// We presume that we'll get notified in time whenever a new aggregate that's relevant to us will be created,
        /// so we can register that specific aggregate.
        /// What we want to prevent is that we'll start pulling in ALL aggregates that are being created,
        /// even though we'll never make use of them
        test('Handle constructor event for unregistered aggregateId', () async {
          givenAggregateIdNotRegistered(scorableId);
          await when(() {
            final payload = ScorableCreated()
              ..aggregateId = scorableId
              ..name = 'Test';
            return receivedRemoteEvent(domainEventFactory.local(
                AggregateId.of(scorableId), 0, payload));
          });
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0);
          thenAggregateShouldNotBeCached(scorableId);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        test('Handle constructor event for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          await when(() => receivedRemoteEvent(
              domainEventFactory.local(AggregateId.of(scorableId), 0,
                  ScorableCreated()
                    ..aggregateId = scorableId
                    ..name = 'Test'))
          );
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
          // TODO: but the cached state is not up-to-date, our whole "given event" premise is messed up... there's no WHEN action...
        });

        /// When a new constructor event tries to create an aggregate for an already existing aggregateId,
        /// an exception will be thrown
        /// TODO: move to EventStore tests
        test('Storing constructor event for already existing registered, cached aggregateId', () async {
          final eventId1 = 'eventId1';
          final eventId2 = 'eventId2';
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1', 0, eventId1);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
          try {
            givenScorableCreatedEvent(scorableId, 'TEST 1', 0, eventId2);
            fail('InvalidEventException expected');
          } on InvalidEventException catch (exception) {
            expect(exception.event.eventId, equals(eventId2));
            expect(exception.event.sequence, equals(0));
          }
        });

        /// When a new constructor event tries to create an aggregate for an already existing aggregateId,
        /// an exception should be thrown
        test('Handle constructor event for already existing registered, cached aggregateId', () async {
          final eventId1 = 'eventId1';
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'TEST 1', 0, eventId1);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(scorableId));
          final conflictingEvent = domainEventFactory.local(
              AggregateId.of(scorableId),
              0,
              ScorableCreated()
                ..aggregateId = scorableId
                ..name = 'TEST 1');
          await when(() => receivedRemoteEvent(conflictingEvent));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(conflictingEvent, 'Sequence invalid'));
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
          await when(() => evictAggregateFromCache(scorableId));
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
          sleep(Duration(milliseconds: 10));
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1);
          thenAggregateShouldBeCached(scorableId);
          await when(() => evictAggregateFromCache(scorableId));
          thenAggregateShouldNotBeCached(scorableId);
          givenParticipantAddedEvent(scorableId, 'PARTICIPANT_ID', 'Player One');
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ParticipantAdded, 1);
          await eventually(() => thenAggregateShouldNotBeCached(scorableId));
        });

        test('Handle regular event for unregistered (non-cached) aggregateId', () async {
          givenAggregateIdNotRegistered(scorableId);
          await when(() => receivedRemoteEvent(domainEventFactory.local(AggregateId.of(scorableId), 0, 'TEST 1')));
          thenAggregateShouldNotBeRegistered(scorableId);
          thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0);
        });

        test('Handle regular event for unregistered aggregateId', () async {
          givenAggregateIdNotRegistered(scorableId);
          await when(() => receivedRemoteEvent(domainEventFactory.local(AggregateId.of(scorableId), 0, 'TEST 1')));
          thenAggregateShouldNotBeCached(scorableId);
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
      });

      // TODO: test only DomainEvents for registered aggregates should be stored
      // TODO: test caching of aggregates?
      //  -> or should these also be pulled up to the Scorekeeper instance? It's be

      /// In case events are added out-of-sync, we should raise a SystemEvent...
      group('Receiving remote events out of sync', () {

        late DomainEvent event1;

        late DomainEvent event2;

        late DomainEvent event2b;

        late DomainEvent event2c;

        late DomainEvent event3;

        late DomainEvent event4;

        late AggregateId aggregateId;

        setUp(() {
          aggregateId = AggregateId.random();
          eventStore.registerAggregateId(aggregateId);
          final payload1 = ScorableCreated()
            ..aggregateId = aggregateId.id
            ..name = 'Test';
          event1 = domainEventFactory.local(aggregateId, 0, payload1);
          final payload2 = ParticipantAdded()
            ..aggregateId = aggregateId.id
            ..participant = Participant('', '');
          event2 = domainEventFactory.local(aggregateId, 1, payload2);
          final payload3 = ParticipantAdded()
            ..aggregateId = aggregateId.id
            ..participant = Participant('', '');
          event3 = domainEventFactory.local(aggregateId, 2, payload3);
          final payload4 = ParticipantAdded()
            ..aggregateId = aggregateId.id
            ..participant = Participant('', '');
          event4 = domainEventFactory.local(aggregateId, 1, payload4);
          // Same aggregate, same sequence, same payload, different UUID, so different origin
          event2b = domainEventFactory.local(aggregateId, 1, payload2);
          // Same aggregate, same sequence, different payload
          event2c = domainEventFactory.local(aggregateId, 1, payload3);
        });

        /// Missing event 3... eventManager should wait and possibly check the remote for event 3
        test('Missing an event in the sequence', () async {
          givenAggregateIdRegistered(aggregateId.id);
          givenLocallyPersistedEvent(event1);
          givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event4));
          thenNoExceptionShouldBeThrown();
          // TODO: mss op aparte queue houden? of verwijderen en remote terug aanroepen?
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event4, 'Sequence invalid'));
        });

        /// Missing event 3 received after event 4
        test('Receiving missing event in the sequence', () async {
          givenAggregateIdRegistered(aggregateId.id);
          givenLocallyPersistedEvent(event1);
          givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event4));
          await when(() => receivedRemoteEvent(event3));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event4, 'Sequence invalid'));
          // TODO: then 3 and 4 should be emitted / applied to aggregate !?
          // TODO: what with the LinkedHashSet ordering???
        });

        /// Receiving the same event twice, the duplicate event should just be ignored
        test('Duplicate DomainEvent in the sequence can be ignored', () async {
          givenAggregateIdRegistered(aggregateId.id);
          givenLocallyPersistedEvent(event1);
          givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event2));
          thenNoExceptionShouldBeThrown();
          thenNoSystemEventShouldBePublished();
          // TODO: then duplicate event should be logged?
        });

        /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
        test('DomainEvent with matching sequence and payload', () async {
          givenAggregateIdRegistered(aggregateId.id);
          givenLocallyPersistedEvent(event1);
          thenNoExceptionShouldBeThrown();
          givenLocallyPersistedEvent(event2);
          thenNoExceptionShouldBeThrown();
          await when(() => receivedRemoteEvent(event2b));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event2b, 'Sequence invalid'));
        });

        /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
        test('DomainEvent with matching sequence, different payload', () async {
          givenAggregateIdRegistered(aggregateId.id);
          givenLocallyPersistedEvent(event1);
          thenNoExceptionShouldBeThrown();
          givenLocallyPersistedEvent(event2);
          thenNoExceptionShouldBeThrown();
          await when(() => receivedRemoteEvent(event2c));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event2c, 'Sequence invalid'));
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

      group('Constructor commands', () {

        /// A Constructor Command should result in a newly created, registered and cached Aggregate
        /// We want this in cache because the high probability of extra commands following the initial one
        test('Handle constructor command for non-existing unregistered, non-cached aggregateId', () async {
          givenNoAggregateKnownWithId(scorableId);
          givenAggregateIdEvictedFromCache(scorableId);
          await when(() => createScorableCommand(scorableId, 'Test Scorable 1'));
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
        test('Handle constructor command for already existing registered, cached aggregateId', () async {
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
          await when(() => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'));
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
          // TODO: No longer possible, as we can't store invalid events with our current "given" statements
          // perhaps there's still another way to set this up?
          // givenAggregateIdNotRegistered(scorableId);
          // givenAggregateIdEvictedFromCache(scorableId);
          // givenScorableCreatedEvent(scorableId, 'Test Scorable');
          // await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 0));
        });

        test('Command should always have an aggregateId value', () {
          givenAggregateIdRegistered(scorableId);
          givenAggregateIdCached(scorableId);
          givenScorableCreatedEvent(scorableId, 'Test Scorable');
          final invalidCommand = AddParticipant()
            ..aggregateId = '';
          when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand, 'aggregateId is required'));
        });

        test('Command should always have an aggregateId property', () {
          final invalidCommand = Object();
          when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand, 'aggregateId is required'));
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
          await when(() => createScorableCommand(scorableId, 'Test'));
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ScorableCreated, 1));
          await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ScorableCreated, 1));
          await when(() => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'));
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

      group('Command flow and default Aggregate DTO', () {

        /// When we create a new Aggregate, the Scorekeeper instance should also provide a cached Aggregate DTO.
        /// This DTO is what clients of the Scorekeeper application can actually use to have an immediately up-to-date
        /// instance of the related Aggregate. This way clients can update their internal state without delay.
        /// Of course, this is only useful when the client code runs the command/event handler in the same instance,
        /// but that's exactly what we do here...
        test("Scorekeeper should maintain AggregateDto's that will be cached and automatically kept up-to-date", () {
          final aggregateId = AggregateId.random();
          // Create Scorable
          scorekeeper.handleCommand(CreateScorable()
            ..aggregateId = aggregateId.id
            ..name = 'Test Scorable');
          // Check cached DTO
          final scorableDto = scorekeeper.getCachedAggregateDtoById<ScorableDto>(aggregateId);
          expect(scorableDto, isNotNull);
          expect(scorableDto.name, equals('Test Scorable'));
          expect(scorableDto.aggregateId, equals(aggregateId));
          expect(scorableDto.participants, isEmpty);
          // Add Participant
          final player1 = Participant(Uuid().v4(), 'Player One');
          scorekeeper.handleCommand(AddParticipant()
              ..aggregateId = aggregateId.id
              ..participant = player1
          );
          // Check cached DTO (no need to retrieve the instance again...
          expect(scorableDto.participants, isNotEmpty);
          expect(scorableDto.participants, contains(player1));
          // Adding participants shouldn't be possible
          final player2 = Participant(Uuid().v4(), 'Player Two');
          try {
            scorableDto.participants.add(player2);
          } on Error catch (error) {
            expect(error.toString(), contains('Cannot add to a fixed-length list'));
          }
          // Removing participants shouldn't be possible
          try {
            scorableDto.participants.clear();
          } on Error catch (error) {
            expect(error.toString(), contains('Cannot clear a fixed-length list'));
          }
          expect(scorableDto.participants.length, equals(1));
          expect(scorableDto.participants, contains(player1));
          expect(scorableDto.participants, isNot(contains(player2)));
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

    group('Potential conflicts', () {

      /// We handle our commands synchronously.
      /// When we receive an external event at the same time,
      /// the command will first be handled, the relevant event will be logged,
      /// and in the end, the remote event will be rejected because of invalid sequences
      test('Receiving external event while handling command', () async {
        givenAggregateIdRegistered(scorableId);
        givenAggregateIdCached(scorableId);
        givenScorableCreatedEvent(scorableId, 'Test Scorable');
        givenCacheIsUpToDate(scorableId);
        thenAssertCachedState(scorableId, (Scorable scorable) => expect(scorable.name, equals('Test Scorable')));
        // Make sure handling commands takes a while
        commandHandler.addHandlerInterceptor((beforeAfter, aggregate, command) async {
          if (command is AddParticipant && command.participant.name == 'Player One' && beforeAfter == 'BEFORE') {
            sleep(Duration(milliseconds: 10));
            return new Future.delayed(const Duration(milliseconds: 10), () => null);
          }
        });
        // Set up the (conflicting) remote event
        final participant = Participant(Uuid().v4(), 'Player Two');
        final remoteDomainEvent = domainEventFactory.local(
            AggregateId.of(scorableId),
            2,
            ParticipantAdded()
              ..aggregateId = scorableId
              ..participant = participant
        );
        // Let's presume adding participant One takes a while...
        await whenSimultaneously(
          // First action: the command
          () => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'),
          // Second action: the remote event
          () => receivedRemoteEvent(remoteDomainEvent),
        );
        // Because our (currenty) synchronous behaviour, the command will be handled without interrupting for the remote event
        // meaning the remote event will become stale...

        await Future.delayed(const Duration(milliseconds: 1000));
        await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ScorableCreated, 1));
        await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ParticipantAdded, 1));
        await eventually(() => thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(remoteDomainEvent, 'Sequence invalid')));
        thenAggregateShouldBeCached(scorableId);
        // Check if Participant is actually added
        thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
          expect(scorable.participants, isNotNull);
          expect(scorable.participants.length, equals(1));
          expect(scorable.participants[0].name, equals('Player One'));
        });
      });

      /// This case should actually not be possible on the local client,
      /// but it could be possible if we provide a REST client or something that multiple clients can send commands to.
      test('Handling command while receiving another command', () async {
        // TODO: implement!
      });

      /// ATOMICITY
      /// When the handling of a command results in an exception while handling the resulting events
      /// Then the events should not be stored or emitted, and the actual command handling should fail.
      ///
      /// Note that we invest heavily in synchronous command handling,
      /// in an attempt to keep write consistency as high as possible.
      /// If we would allow asynchronous command handling, multiple commands for the same Aggregate could compete
      /// and possibly conflict with each other.
      test('Exception while handling domain event', () async {
        givenAggregateIdRegistered(scorableId);
        givenAggregateIdCached(scorableId);
        givenScorableCreatedEvent(scorableId, 'Test Scorable');
        givenCacheIsUpToDate(scorableId);
        // Make sure that the handling of the command results in multiple events,
        // because ALL previously applied events should be undone as well.
        commandHandler.addHandlerInterceptor((beforeAfter, aggregate, command) {
          if ('BEFORE' == beforeAfter && command is AddParticipant) {
            final participant = Participant('', 'Player Two');
            aggregate.apply(ParticipantAdded()..participant = participant);
          }
        });
        // Make sure handling of the applied events of the commands throws an exception
        var mockException = Exception('Some random exception thrown in the event handler');
        eventHandler.addHandlerInterceptor((aggregate, event) {
          if (event.payload is ParticipantAdded && event.payload.participant.name == 'Player One') {
            throw mockException;
          }
        });
        when(() => addParticipantCommand(scorableId, 'PARTICIPANT_ID', 'Player One'));
        await eventually(() => thenExceptionShouldBeThrown(mockException));
        // The first event should be handled (add Player Two), but it should not be stored because of failure adding Player One
        thenEventTypeShouldBeHandledNumberOfTimes(scorableId, ParticipantAdded, 1);
        thenEventTypeShouldBeStoredNumberOfTimes(scorableId, ParticipantAdded, 0);
        thenNoSystemEventShouldBePublished();
        // Participant cannot be added
        thenAssertCachedState<Scorable>(scorableId, (Scorable scorable) {
          expect(scorable.participants, isNotNull);
          expect(scorable.participants.length, equals(0));
        });
      });

      /// ATOMICITY
      /// When one or more locally created events cannot be stored (after handling the command),
      /// then command handler should fail and none of the related events should be stored
      test('Exception while storing locally emitted domain event', () async {
        // TODO: implement!
      });

      /// CONSISTENCY? ATOMICITY?
      /// When we receive a domain event from a remote source,
      /// and it cannot be stored for some reason
      /// we should raise an exception.
      /// This way the event broker can possibly detect the failure and retry.
      ///
      /// TODO: what if we fail to do so multiple times in a row? Because of invalid sequence!!??
      test('Exception while storing remotely received domain event', () async {
        // TODO: implement!
      });

      /// TODO: mss commands bijhouden totdat remote storage oke is?
      /// als mechanisme om events automatisch te reconciliaten?
      /// eerst naar remote state forwarden, als command dan geldig is, mogen die events applied worden?
      /// indien command geweigerd wordt, effectief conflict gooien?

    });

    group('Remote event publication', () {

      test('Events resulting from local commands should be published remotely', () async {
        await when(() => createScorableCommand(scorableId, 'Test'));
        thenEventTypeShouldBePublishedNumberOfTimes(scorableId, ScorableCreated, 1);
      });

      // TODO: failed commands should not result in publication of events

    });

  });

}


