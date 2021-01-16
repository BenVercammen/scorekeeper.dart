import 'dart:collection';

import 'package:example_domain/example.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:test/test.dart';


/// Wrapper class that allows us to keep track of which events have been handled
class EventHandlerCountWrapper<T extends EventHandler> implements EventHandler {

  final T _eventHandler;

  final Map<AggregateId, Set<DomainEvent>> _handledEvents = HashMap();

  EventHandlerCountWrapper(this._eventHandler);

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

void main() {

  /// The last thrown exception in a "when" statement
  Exception _lastThrownWhenException;

  group('Scorekeeper', () {

    const SCORABLE_ID = 'SCORABLE_ID';

    Scorekeeper scorekeeper;

    AggregateCache aggregateCache;

    EventManager localEventManager;

    EventManager remoteEventManager;

    CommandHandler commandHandler;

    EventHandlerCountWrapper<ScorableEventHandler> eventHandler;

    setUp(() {
      localEventManager = EventManagerInMemoryImpl();
      remoteEventManager = EventManagerInMemoryImpl();
      aggregateCache = AggregateCacheImpl();
      commandHandler = ScorableCommandHandler();
      eventHandler = EventHandlerCountWrapper<ScorableEventHandler>(ScorableEventHandler());
      scorekeeper = Scorekeeper(localEventManager, remoteEventManager, aggregateCache)
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
    void givenScorableCreatedEvent(String aggregateId, String name, [EventId eventId]) {
      final scorableCreated = ScorableCreated()
        ..aggregateId = aggregateId
        ..name = name;
      // Store and publish
      localEventManager.storeAndPublish(DomainEvent.of(eventId??EventId.local(), AggregateId.of(aggregateId), scorableCreated));
    }

    /// Given the ParticipantAdded event
    void givenParticipantAddedEvent(String aggregateId, String participantId, String participantName, [EventId eventId]) {
      final participantAdded = ParticipantAdded()
        ..aggregateId = aggregateId;
      final participant = Participant()
        ..participantId = participantId
        ..name = participantName;
      participantAdded.participant = participant;
      // Store and publish
      localEventManager.storeAndPublish(DomainEvent.of(eventId??EventId.local(), AggregateId.of(aggregateId), participantAdded));
    }

    /// Given no aggregate with given Id is known in Scorekeeper
    void givenNoAggregateKnownWithId(String aggregateIdValue) {
      final aggregateId = AggregateId.of(aggregateIdValue);
      aggregateCache.purge(aggregateId);
    }

    void when(Function() callback) {
      try {
        _lastThrownWhenException = null;
        callback();
      } on Exception catch (exception) {
        _lastThrownWhenException = exception;
      }
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
      final eventsForAggregate = localEventManager.getEventsForAggregate(AggregateId.of(aggregateId));
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

    /// Then a SystemEvent of the given type should be published
    void thenSystemEventShouldBePublished(SystemEvent expectedEvent) {
      expect(localEventManager.getSystemEvents().where((actualEvent) {
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

      test('Constructor requires local EventManager', () {
        try {
          Scorekeeper(null, null, AggregateCacheImpl());
          fail('Instantiating without local EventManager instance should fail');
        } on Exception catch (exception) {
          expect(exception.toString(), contains('Local EventManager instance is required'));
        }
      });

      test('Constructor requires an AggregateCache', () {
        try {
          Scorekeeper(EventManagerInMemoryImpl(), null, null);
          fail('Instantiating without AggregateCache instance should fail');
        } on Exception catch (exception) {
          expect(exception.toString(), contains('AggregateCache instance is required'));
        }
      });


      group('Scorekeeper without handlers', () {

        Scorekeeper scorekeeper;

        setUp(() {
          scorekeeper = Scorekeeper(EventManagerInMemoryImpl(), null, AggregateCacheImpl());
        });

        /// Commands that can't be handled, should raise an exception
        test('Command without handler', () {
          try {
            scorekeeper.handleCommand(CreateScorable()
              ..name = 'Test'
              ..aggregateId = AggregateId
                  .random()
                  .id);
          } on Exception catch (exception) {
            expect(exception.toString(), contains("No command handler registered for Instance of 'CreateScorable'"));
          }
        });

        /// Events that aren't handled, won't raise any exceptions (for now)
        test('Event without handler', () {
          scorekeeper.handleEvent(DomainEvent.of(EventId.local(), AggregateId.random(), CreateScorable()));
        });
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
    ///                             if the aggregateId is registered within the EventManager
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
          givenAggregateIdRegistered(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenAggregateShouldNotBeCached(SCORABLE_ID);
          await eventually(() => thenAggregateShouldNotBeCached(SCORABLE_ID));
        });

        /// For a non-registered aggregateId, the constructor event should not even be stored in the local event manager
        /// We presume that we'll get notified in time whenever a new aggregate that's relevant to us will be created,
        /// so we can register that specific aggregate.
        /// What we want to prevent is that we'll start pulling in ALL aggregates that are being created,
        /// even though we'll never make use of them
        test('Handle constructor event for unregistered aggregateId', () async {
          givenAggregateIdNotRegistered(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 0);
          thenAggregateShouldNotBeCached(SCORABLE_ID);
          await eventually(() => thenAggregateShouldNotBeCached(SCORABLE_ID));
        });

        test('Handle constructor event for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(SCORABLE_ID));
        });

        /// When a new constructor event tries to create an aggregate for an already existing aggregateId,
        /// the system should ignore this event and raise a new SystemEvent
        test('Handle constructor event for already existing registered, cached aggregateId', () async {
          final eventId1 = EventId.local();
          final eventId2 = EventId.local();
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1', eventId1);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(SCORABLE_ID));
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1', eventId2);
          await eventually(() {
            final eventNotHandled = EventNotHandled(SystemEventId.local(), eventId2, 'Aggregate with id $SCORABLE_ID already exists and cannot be created again');
            thenSystemEventShouldBePublished(eventNotHandled);
          });
        });

        // TODO: only not-yet-handled events should get handled... (so look at EventId!)
        //  but that's probably more of the EventManager's concern/responsibility??


        /// TODO: what if a constructor event tries to create an already created aggregateId
        ///  this could pop up when the RemoteEventManager sends us an event..
        ///  Do we generate some kind of SystemEvent and ignore the actual Event?
        ///  Just pass the bucket on and handle this situation when it actually arises?

      });

      group('Regular events', () {

        test('Handle regular event for registered, non-cached aggregateId', () async {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldNotBeCached(SCORABLE_ID));
          when(() => evictAggregateFromCache(SCORABLE_ID));
          thenAggregateShouldNotBeCached(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          givenParticipantAddedEvent(SCORABLE_ID, 'PARTICIPANT_ID', 'Player One');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ParticipantAdded, 1));
          await eventually(() => thenAggregateShouldNotBeCached(SCORABLE_ID));
        });

        /// After an AggregateId has been evicted from cache, it should no longer be cached
        test('Handle regular event for registered, evicted-from-cache aggregateId', () async {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenAggregateShouldBeCached(SCORABLE_ID);
          when(() => evictAggregateFromCache(SCORABLE_ID));
          thenAggregateShouldNotBeCached(SCORABLE_ID);
          givenParticipantAddedEvent(SCORABLE_ID, 'PARTICIPANT_ID', 'Player One');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ParticipantAdded, 1);
          await eventually(() => thenAggregateShouldNotBeCached(SCORABLE_ID));
        });

        test('Handle regular event for unregistered, non-cached aggregateId', () {
          givenAggregateIdNotRegistered(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'TEST 1');
          thenAggregateShouldNotBeRegistered(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 0);
        });

        test('Handle regular event for registered, cached aggregateId', () async {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'Test 1');
          givenParticipantAddedEvent(SCORABLE_ID, 'PARTICIPANT_ID', 'Player One');
          await eventually(() => thenAggregateShouldBeCached(SCORABLE_ID));
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ParticipantAdded, 1);
          // Cached state should reflect the handled event...
          thenAssertCachedState<Scorable>(SCORABLE_ID, (Scorable scorable) {
            expect(scorable.name, equals('Test 1'));
            expect(scorable.participants.length, equals(1));
          });
        });

        test('Handle regular event for unregistered aggregateId', () {
          givenAggregateIdNotRegistered(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'Test');
          thenAggregateShouldNotBeCached(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 0);
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
          givenNoAggregateKnownWithId(SCORABLE_ID);
          givenAggregateIdEvictedFromCache(SCORABLE_ID);
          when(() => createScorableCommand(SCORABLE_ID, 'Test Scorable 1'));
          thenAggregateShouldBeCached(SCORABLE_ID);
          thenAggregateShouldBeRegistered(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          // Check cached values (this is actually testing the domain itself, so not really something we need to do here)
          thenAssertCachedState<Scorable>(SCORABLE_ID, (Scorable scorable) {
            expect(scorable, isNotNull);
            expect(scorable.aggregateId, equals(AggregateId.of(SCORABLE_ID)));
            expect(scorable.name, equals('Test Scorable 1'));
          });
        });

        test('Handle constructor command for non-existing registered, non-cached aggregateId', () {
          givenNoAggregateKnownWithId(SCORABLE_ID);
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdEvictedFromCache(SCORABLE_ID);
          when(() => createScorableCommand(SCORABLE_ID, 'Test Scorable 1'));
          thenAggregateShouldBeCached(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(SCORABLE_ID);
        });

        test('Handle constructor command for non-existing registered, cached aggregateId', () {
          givenNoAggregateKnownWithId(SCORABLE_ID);
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          when(() => createScorableCommand(SCORABLE_ID, 'Test Scorable 1'));
          thenAggregateShouldBeCached(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(SCORABLE_ID);
        });

        test('Handle constructor command for non-existing unregistered, cached aggregateId', () {
          givenNoAggregateKnownWithId(SCORABLE_ID);
          givenAggregateIdNotRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          when(() => createScorableCommand(SCORABLE_ID, 'Test Scorable 1'));
          thenAggregateShouldBeCached(SCORABLE_ID);
          thenAggregateShouldBeRegistered(SCORABLE_ID);
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
        });

        /// Scorekeeper should block new constructor commands for already existing aggregates
        test('Handle constructor command for already existing registered, cached aggregateId', () {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'Test Scorable 1');
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          when(() => createScorableCommand(SCORABLE_ID, 'Test Scorable 1'));
          thenExceptionShouldBeThrown(AggregateIdAlreadyExistsException(AggregateId.of(SCORABLE_ID)));
          thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenAggregateShouldBeCached(SCORABLE_ID);
          thenAggregateShouldBeRegistered(SCORABLE_ID);
        });

      });

      group('Regular commands', () {

        test('Handle regular command for unregistered, non-cached aggregateId', () async {
          givenAggregateIdRegistered(SCORABLE_ID);
          givenAggregateIdCached(SCORABLE_ID);
          givenScorableCreatedEvent(SCORABLE_ID, 'Test Scorable');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(SCORABLE_ID, ScorableCreated, 1));
          // TODO: dat "should be handled" ook in andere tests nagaan!
          await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(SCORABLE_ID, ScorableCreated, 1));
          when(() => addParticipantCommand(SCORABLE_ID, 'PARTICIPANT_ID', 'Player One'));
          thenEventTypeShouldBeHandledNumberOfTimes(SCORABLE_ID, ScorableCreated, 1);
          thenEventTypeShouldBeHandledNumberOfTimes(SCORABLE_ID, ParticipantAdded, 1);
          thenAggregateShouldBeCached(SCORABLE_ID);
          // Check if Participant is actually added
          thenAssertCachedState<Scorable>(SCORABLE_ID, (Scorable scorable) {
            expect(scorable.participants, isNotNull);
            expect(scorable.participants.length, equals(1));
          });
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


