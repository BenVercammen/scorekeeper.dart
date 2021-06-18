import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'features/step_definitions.dart';


/// Wrapper class that allows us to keep track of which events have been handled
class _EventHandlerCountWrapper<T extends EventHandler> implements EventHandler<Aggregate<AggregateId>, AggregateId> {

  final T _eventHandler;

  final Map<AggregateId, Set<DomainEvent>> _handledEvents = HashMap();

  Function(Aggregate aggregate, DomainEvent domainEvent)? _handlerInterceptor;

  _EventHandlerCountWrapper(this._eventHandler);

  @override
  void handle(Aggregate aggregate, DomainEvent<Aggregate, AggregateId> event) {
    print('======== HANDLE EVENT');
    _handledEvents.putIfAbsent(aggregate.aggregateId, () => <DomainEvent>{});
    if (null == _handlerInterceptor) {
      _eventHandler.handle(aggregate, event);
    } else {
      _handlerInterceptor!(aggregate, event);
    }
    print('======== HANDLE EVENT DONE');
    _handledEvents[aggregate.aggregateId]!.add(event);
  }

  @override
  Aggregate newInstance(AggregateId aggregateId) {
    return _eventHandler.newInstance(aggregateId);
  }

  @override
  bool handles(DomainEvent<Aggregate<AggregateId>, AggregateId> event) {
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
    print('======== START');
    if (null != _handlerInterceptor) {
      _handlerInterceptor!("BEFORE", aggregate, command);
    }
    print('======== HANDLE COMMANd');
    _commandHandler.handle(aggregate, command);
    print('======== COMMANd HANDLED');
    if (null != _handlerInterceptor) {
      _handlerInterceptor!("AFTER", aggregate, command);
    }
    print('======== DONONNNN');
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

void main() {

  /// The last thrown exception in a "when" statement
  late Exception? _lastThrownWhenException;

  late TracingLogger _logger;

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
    Future<void> givenAggregateIdRegistered(AggregateId aggregateId) async {
      scorekeeper.registerAggregate(aggregateId, Scorable);
    }

    /// Given we did not register for notifications of the aggregate with aggregateId
    Future<void> givenAggregateIdNotRegistered(AggregateId aggregateId) async {
      scorekeeper.unregisterAggregate(aggregateId);
    }

    /// Given the aggregate with Id should be cached by the Scorekeeper
    Future<void> givenAggregateIdCached(AggregateId aggregateId) async {
      await scorekeeper.loadAndAddAggregateToCache(aggregateId, Scorable);
    }

    /// Given the aggregate with Id is not cached by the Scorekeeper
    Future<void> givenAggregateIdEvictedFromCache(AggregateId aggregateId) async {
      scorekeeper.evictAggregateFromCache(aggregateId);
    }

    /// Given the DomainEvent is already persisted locally
    Future<void> givenLocallyPersistedEvent(DomainEvent domainEvent) async {
      await eventStore.storeDomainEvent(domainEvent);
    }

    /// Given the ScorableCreatedEvent with parameters
    Future<void> givenScorableCreatedEvent(ScorableAggregateId aggregateId, String name, [int? sequence, String? eventId]) async {
      final scorableCreated = ScorableCreated()
        ..scorableId = aggregateId.scorableId
        ..name = name;
      // Store and publish
      eventId ??= Uuid().v4().toString();
      sequence ??= await eventStore.nextSequenceForAggregate(aggregateId);
      final event = domainEventFactory.remote(eventId, aggregateId, sequence, DateTime.now(), scorableCreated);
      await eventStore.storeDomainEvent(event);
    }

    /// Given the ParticipantAdded event
    Future<void> givenParticipantAddedEvent(ScorableAggregateId aggregateId, String participantId, String participantName, [String? eventId]) async {
      final participantAdded = ParticipantAdded()
        ..scorableId = aggregateId.scorableId;
      final participant = Participant(participantId: ParticipantId(uuid: participantId), participantName: participantName);
      participantAdded.participant = participant;
      // Store and publish
      final sequence = await eventStore.nextSequenceForAggregate(aggregateId);
      final event = domainEventFactory.local(aggregateId, sequence, participantAdded);
      await eventStore.storeDomainEvent(event);
    }

    /// Given no aggregate with given Id is known in Scorekeeper
    Future<void> givenNoAggregateKnownWithId(AggregateId aggregateId) async {
      aggregateCache.purge(aggregateId);
    }

    Future<void> givenCacheIsUpToDate(AggregateId aggregateId) async {
      await scorekeeper.refreshCache(Scorable, aggregateId);
    }

    Future<void> when(Function() callback) async {
      print('=========== WHEN');
      try {
        _lastThrownWhenException = null;
        await Future.sync(() => callback());
        print('=========== WHEN DONE');
      } on Exception catch (exception) {
        print('=========== WHEN EXCEPTION');
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
    Future<void> command(dynamic command) async {
      await scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    Future<void> createScorableCommand(ScorableId scorableId, String name) async {
      final command = CreateScorable()
        ..scorableId = scorableId
        ..name = name;
      await scorekeeper.handleCommand(command);
    }

    /// When constructor command is sent to Scorekeeper
    Future<void> addParticipantCommand(ScorableId aggregateId, ParticipantId participantId, String participantName) async {
      final command = AddParticipant()
        ..scorableId = aggregateId
        ..participant = Participant(participantId: participantId, participantName: participantName);
      await scorekeeper.handleCommand(command);
    }

    /// When the RemoteEventListener receives a new DomainEvent
    Future<void> receivedRemoteEvent(DomainEvent domainEvent) async {
      return await Future.sync(() => remoteEventListener.emitEvent(domainEvent));
    }

    /// When an aggregate with given Id is evicted from cache
    void evictAggregateFromCache(AggregateId aggregateId) {
      scorekeeper.evictAggregateFromCache(aggregateId);
    }

    /// Eventually means asynchronously, so we'll just wait a few millis to check
    Future<void> eventually(Function() callback) async {
      await Future.delayed(const Duration(milliseconds: 100));
      callback();
    }

    /// Then the cached aggregate should ...
    void thenAssertCachedState<T extends Aggregate>(AggregateId aggregateId, Function(T aggregate) callback) {
      final aggregate = aggregateCache.get<T>(aggregateId);
      callback(aggregate);
    }

    /// Then the aggregate with given Id should be cached
    void thenAggregateShouldBeCached(AggregateId aggregateId) {
      expect(aggregateCache.contains(aggregateId), equals(true));
    }

    /// Then the aggregate with given Id should not be cached
    void thenAggregateShouldNotBeCached(AggregateId aggregateId) {
      expect(aggregateCache.contains(aggregateId), equals(false));
    }

    /// Then the aggregate with given Id should not be registered
    void thenAggregateShouldNotBeRegistered(AggregateId aggregateId) {
      expect(scorekeeper.isRegistered(aggregateId), equals(false));
    }

    /// Then the aggregate with given Id should be registered
    void thenAggregateShouldBeRegistered(AggregateId aggregateId) {
      expect(scorekeeper.isRegistered(aggregateId), equals(true));
    }

    /// Then the event with payload of given type should be stored exactly [numberOfTimes] times for aggregate with Id
    Future<void> thenEventTypeShouldBeStoredNumberOfTimes(AggregateId aggregateId, Type eventType, int numberOfTimes) async {
      final eventsForAggregate = await eventStore.getDomainEvents(aggregateId: aggregateId).toSet();
      final equalEventPayloads = eventsForAggregate.toSet()
        ..retainWhere((event) => event.payload.runtimeType == eventType);
      expect(equalEventPayloads.length, equals(numberOfTimes));
    }

    /// Then the event with payload of given type should actually be handled exactly [numberOfTimes] for the aggregate with Id
    void thenEventTypeShouldBeHandledNumberOfTimes(AggregateId aggregateId, Type eventType, int numberOfTimes) {
      expect(eventHandler.countHandledEvents(aggregateId, eventType), equals(numberOfTimes));
    }

    /// Then the event with payload of given type should be published exactly [numberOfTimes] for the aggregate with Id
    void thenEventTypeShouldBePublishedNumberOfTimes(AggregateId aggregateId, Type eventType, int numberOfTimes) {
      final matches = remoteEventPublisher.publishedDomainEvents.where((publishedEvent) {
        return publishedEvent.aggregateId.id == aggregateId && publishedEvent.payload.runtimeType == eventType;
      });
      expect(matches.length, equals(numberOfTimes));
    }

    /// Then no events should be published
    void thenNoEventsShouldBePublishedForAggregateId(AggregateId aggregateId) {
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
      // TODO: Wrapped in an eventually() to avoid
      //  Concurrent modification during iteration: Instance of '_CompactLinkedHashSet<SystemEvent>'.
      // Not sure why this is... :/
      await eventually(() => () async {
            var systemEvents = await eventStore.getSystemEvents().toSet();
            expect(
                systemEvents.where((actualEvent) {
                  if (actualEvent.runtimeType != expectedEvent.runtimeType) {
                    return false;
                  }
                  if (actualEvent is EventNotHandled &&
                      expectedEvent is EventNotHandled) {
                    return actualEvent.notHandledEvent.eventId ==
                            expectedEvent.notHandledEvent.eventId &&
                        actualEvent.reason.contains(expectedEvent.reason);
                  }
                  return false;
                }).length,
                equals(1));
          });
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
              ..scorableId = ScorableAggregateId.random().scorableId);
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
          final aggregateId = ScorableAggregateId.random();
          scorekeeper.registerAggregate(aggregateId, Scorable);
          await givenScorableCreatedEvent(aggregateId, 'Test');
          thenAggregateShouldBeRegistered(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          // unregister
          scorekeeper.unregisterAggregate(aggregateId);
          thenAggregateShouldNotBeRegistered(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 0);
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
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          final payload = ScorableCreated()
            ..scorableId = aggregateId.scorableId
            ..name = 'Test';
          await when(() {
            return receivedRemoteEvent(
            domainEventFactory.local(aggregateId, 0, payload));
          });
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1));
          thenAggregateShouldNotBeCached(aggregateId);
          await eventually(() => thenAggregateShouldNotBeCached(aggregateId));
          thenNoEventsShouldBePublishedForAggregateId(aggregateId);
        });

        /// For a non-registered aggregateId, the constructor event should not even be stored in the local event manager
        /// We presume that we'll get notified in time whenever a new aggregate that's relevant to us will be created,
        /// so we can register that specific aggregate.
        /// What we want to prevent is that we'll start pulling in ALL aggregates that are being created,
        /// even though we'll never make use of them
        test('Handle constructor event for unregistered aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdNotRegistered(aggregateId);
          await when(() {
            final payload = ScorableCreated()
              ..scorableId = aggregateId.scorableId
              ..name = 'Test';
            return receivedRemoteEvent(domainEventFactory.local(
                aggregateId, 0, payload));
          });
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 0);
          thenAggregateShouldNotBeCached(aggregateId);
          await eventually(() => thenAggregateShouldNotBeCached(aggregateId));
        });

        test('Handle constructor event for registered, cached aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await when(() => receivedRemoteEvent(
              domainEventFactory.local(aggregateId, 0,
                  ScorableCreated()
                    ..scorableId = aggregateId.scorableId
                    ..name = 'Test'))
          );
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1));
          await eventually(() => thenAggregateShouldBeCached(aggregateId));
          // TODO: but the cached state is not up-to-date, our whole "given event" premise is messed up... there's no WHEN action...
        });

        /// When a new constructor event tries to create an aggregate for an already existing aggregateId,
        /// an exception will be thrown
        /// TODO: move to EventStore tests
        test('Storing constructor event for already existing registered, cached aggregateId', () async {
          final eventId1 = 'eventId1';
          final eventId2 = 'eventId2';
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'TEST 1', 0, eventId1);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(aggregateId));
          try {
            await givenScorableCreatedEvent(aggregateId, 'TEST 1', 0, eventId2);
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
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'TEST 1', 0, eventId1);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldBeCached(aggregateId));
          final conflictingEvent = domainEventFactory.local(
              aggregateId,
              0,
              ScorableCreated()
                ..scorableId = aggregateId.scorableId
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
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'TEST 1');
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await eventually(() => thenAggregateShouldNotBeCached(aggregateId));
          await when(() => evictAggregateFromCache(aggregateId));
          thenAggregateShouldNotBeCached(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await givenParticipantAddedEvent(aggregateId, 'PARTICIPANT_ID', 'Player One');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ParticipantAdded, 1));
          await eventually(() => thenAggregateShouldNotBeCached(aggregateId));
        });

        /// After an AggregateId has been evicted from cache, it should no longer be cached
        test('Handle regular event for registered, evicted-from-cache aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'TEST 1');
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1));
          thenAggregateShouldBeCached(aggregateId);
          await when(() => evictAggregateFromCache(aggregateId));
          thenAggregateShouldNotBeCached(aggregateId);
          await givenParticipantAddedEvent(aggregateId, 'PARTICIPANT_ID', 'Player One');
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ParticipantAdded, 1);
          await eventually(() => thenAggregateShouldNotBeCached(aggregateId));
        });

        test('Handle regular event for unregistered, non-cached aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdNotRegistered(aggregateId);
          await when(() => receivedRemoteEvent(domainEventFactory.local(aggregateId, 0, 'TEST 1')));
          thenAggregateShouldNotBeRegistered(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 0);
        });

        test('Handle regular event for registered, cached aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'Test 1');
          await givenParticipantAddedEvent(aggregateId, 'PARTICIPANT_ID', 'Player One');
          // TODO: dus ook scenario's schrijven waarin cache out-of-date is? of zou da nooit mogen?
          await givenCacheIsUpToDate(aggregateId);
          await eventually(() => thenAggregateShouldBeCached(aggregateId));
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ParticipantAdded, 1);
          // Cached state should reflect the handled event...
          thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
            expect(scorable.name, equals('Test 1'));
            expect(scorable.participants.length, equals(1));
          });
        });

        test('Handle regular event for unregistered aggregateId', () async {
          final aggregateId = ScorableAggregateId.random();
          await givenAggregateIdNotRegistered(aggregateId);
          await when(() => receivedRemoteEvent(domainEventFactory.local(aggregateId, 0, 'TEST 1')));
          thenAggregateShouldNotBeCached(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 0);
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
          aggregateId = ScorableAggregateId.random();
          eventStore.registerAggregateId(aggregateId);
          final payload1 = ScorableCreated()
            ..scorableId = ScorableId(uuid: aggregateId.id)
            ..name = 'Test';
          event1 = domainEventFactory.local(aggregateId, 0, payload1);
          final payload2 = ParticipantAdded()
            ..scorableId = ScorableId(uuid: aggregateId.id)
            ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: '');
          event2 = domainEventFactory.local(aggregateId, 1, payload2);
          final payload3 = ParticipantAdded()
            ..scorableId = ScorableId(uuid: aggregateId.id)
            ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: '');
          event3 = domainEventFactory.local(aggregateId, 2, payload3);
          final payload4 = ParticipantAdded()
            ..scorableId = ScorableId(uuid: aggregateId.id)
            ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: '');
          event4 = domainEventFactory.local(aggregateId, 1, payload4);
          // Same aggregate, same sequence, same payload, different UUID, so different origin
          event2b = domainEventFactory.local(aggregateId, 1, payload2);
          // Same aggregate, same sequence, different payload
          event2c = domainEventFactory.local(aggregateId, 1, payload3);
        });

        /// Missing event 3... eventManager should wait and possibly check the remote for event 3
        test('Missing an event in the sequence', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenLocallyPersistedEvent(event1);
          await givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event4));
          thenNoExceptionShouldBeThrown();
          // TODO: mss op aparte queue houden? of verwijderen en remote terug aanroepen?
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event4, 'Sequence invalid'));
        });

        /// Missing event 3 received after event 4
        test('Receiving missing event in the sequence', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenLocallyPersistedEvent(event1);
          await givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event4));
          await when(() => receivedRemoteEvent(event3));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event4, 'Sequence invalid'));
          // TODO: then 3 and 4 should be emitted / applied to aggregate !?
          // TODO: what with the LinkedHashSet ordering???
        });

        /// Receiving the same event twice, the duplicate event should just be ignored
        test('Duplicate DomainEvent in the sequence can be ignored', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenLocallyPersistedEvent(event1);
          await givenLocallyPersistedEvent(event2);
          await when(() => receivedRemoteEvent(event2));
          thenNoExceptionShouldBeThrown();
          thenNoSystemEventShouldBePublished();
          // TODO: then duplicate event should be logged?
        });

        /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
        test('DomainEvent with matching sequence and payload', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenLocallyPersistedEvent(event1);
          thenNoExceptionShouldBeThrown();
          await givenLocallyPersistedEvent(event2);
          thenNoExceptionShouldBeThrown();
          await when(() => receivedRemoteEvent(event2b));
          thenNoExceptionShouldBeThrown();
          thenSystemEventShouldBePublished(domainEventFactory.eventNotHandled(event2b, 'Sequence invalid'));
        });

        /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
        test('DomainEvent with matching sequence, different payload', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenLocallyPersistedEvent(event1);
          thenNoExceptionShouldBeThrown();
          await givenLocallyPersistedEvent(event2);
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

      late ScorableAggregateId aggregateId;

      setUp(() {
        aggregateId = ScorableAggregateId.random();
      });

      /// TODO: Non-constructor commands can only be handled on aggregates that are registered??

      group('Constructor commands', () {

        /// A Constructor Command should result in a newly created, registered and cached Aggregate
        /// We want this in cache because the high probability of extra commands following the initial one
        test('Handle constructor command for non-existing unregistered, non-cached aggregateId', () async {
          await givenNoAggregateKnownWithId(aggregateId);
          await givenAggregateIdEvictedFromCache(aggregateId);
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(aggregateId);
          thenAggregateShouldBeRegistered(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          // Check cached values (this is actually testing the domain itself, so not really something we need to do here)
          thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
            expect(scorable, isNotNull);
            expect(scorable.aggregateId, equals(aggregateId));
            expect(scorable.name, equals('Test Scorable 1'));
          });
        });

        test('Handle constructor command for non-existing registered, non-cached aggregateId', () async {
          await givenNoAggregateKnownWithId(aggregateId);
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdEvictedFromCache(aggregateId);
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(aggregateId);
        });

        test('Handle constructor command for non-existing registered, cached aggregateId', () async {
          await givenNoAggregateKnownWithId(aggregateId);
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          thenAggregateShouldBeRegistered(aggregateId);
        });

        test('Handle constructor command for non-existing unregistered, cached aggregateId', () async {
          await givenNoAggregateKnownWithId(aggregateId);
          await givenAggregateIdNotRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test Scorable 1'));
          thenAggregateShouldBeCached(aggregateId);
          thenAggregateShouldBeRegistered(aggregateId);
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
        });

        /// Scorekeeper should block new constructor commands for already existing aggregates
        test('Handle constructor command for already existing registered, cached aggregateId', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'Test Scorable 1');
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test Scorable 1'));
          thenExceptionShouldBeThrown(AggregateIdAlreadyExistsException(aggregateId));
          await thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1);
          thenAggregateShouldBeCached(aggregateId);
          thenAggregateShouldBeRegistered(aggregateId);
        });

        /// Handling a command should not result in the same event being triggered/handled twice
        test('Handling constructor command should emit event(s) only once', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'Test Scorable 1');
          await eventually(() => thenNoMessageShouldBeLogged(Level.info, 'Received and ignored duplicate Event', 0));
        });

      });

      group('Regular commands', () {

        test('Handle regular command for registered, cached aggregateId', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'Test Scorable');
          await givenCacheIsUpToDate(aggregateId);
          await when(() => addParticipantCommand(aggregateId.scorableId, ParticipantId(uuid: 'PARTICIPANT_ID'), 'Player One'));
          thenEventTypeShouldBeHandledNumberOfTimes(aggregateId, ScorableCreated, 1);
          thenEventTypeShouldBeHandledNumberOfTimes(aggregateId, ParticipantAdded, 1);
          thenAggregateShouldBeCached(aggregateId);
          // Check if Participant is actually added
          thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
            expect(scorable.participants, isNotNull);
            expect(scorable.participants.length, equals(1));
          });
        });

        test('Handle regular command for unregistered, non-cached aggregateId', () async {
          await givenAggregateIdNotRegistered(aggregateId);
          await givenAggregateIdEvictedFromCache(aggregateId);
          await when(() => receivedRemoteEvent(domainEventFactory.local(aggregateId, 0, 'TEST 1')));
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 0));
        });

        test('Command should always have an aggregateId value', () async {
          await givenAggregateIdRegistered(aggregateId);
          await givenAggregateIdCached(aggregateId);
          await givenScorableCreatedEvent(aggregateId, 'Test Scorable');
          final invalidCommand = AddParticipant()
            ..scorableId = ScorableId(uuid: '');
          await when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand, 'aggregateId is required'));
        });

        test('Command should always have an aggregateId property', () async {
          final invalidCommand = Object();
          await when(() => command(invalidCommand));
          thenExceptionShouldBeThrown(InvalidCommandException(invalidCommand, 'aggregateId is required'));
        });

        test('No command handler found', () async {
          scorekeeper.unregisterCommandHandler(commandHandler);
          final unsupportedCommand = CreateScorable()
            ..scorableId = ScorableId(uuid: ScorableAggregateId.random().id);
          await when(() => command(unsupportedCommand));
          thenExceptionShouldBeThrown(UnsupportedCommandException(unsupportedCommand));
        });

        test('Multiple command handlers found', () async {
          final extraCommandHandler = ScorableCommandHandler();
          scorekeeper.registerCommandHandler(extraCommandHandler);
          final duplicateCommand = CreateScorable()
            ..scorableId = ScorableId(uuid: ScorableAggregateId.random().id);
          await when(() => command(duplicateCommand));
          thenExceptionShouldBeThrown(MultipleCommandHandlersException(duplicateCommand));
        });

        /// We had an issue where the events emitted by regular commands would be handled twice.
        /// The tricky part is that the second handled event was handled asynchronously,
        /// so if we don't wait for it in our tests, we'd never notice it...
        /// This test will explicitly wait to make sure that something like that doesn't happen (again).
        test('Regular command should have its emitted events applied only once', () async {
          await when(() => createScorableCommand(aggregateId.scorableId, 'Test'));
          await eventually(() => thenEventTypeShouldBeStoredNumberOfTimes(aggregateId, ScorableCreated, 1));
          await eventually(() => thenEventTypeShouldBeHandledNumberOfTimes(aggregateId, ScorableCreated, 1));
          await when(() => addParticipantCommand(aggregateId.scorableId, ParticipantId(uuid: 'PARTICIPANT_ID'), 'Player One'));
          thenEventTypeShouldBeHandledNumberOfTimes(aggregateId, ScorableCreated, 1);
          thenEventTypeShouldBeHandledNumberOfTimes(aggregateId, ParticipantAdded, 1);
          thenAggregateShouldBeCached(aggregateId);
          // Check if Participant is actually added
          await eventually(() => thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
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
        test("Scorekeeper should maintain AggregateDto's that will be cached and automatically kept up-to-date", () async {
          final aggregateId = ScorableAggregateId.random();
          // Create Scorable
          await scorekeeper.handleCommand(CreateScorable()
            ..scorableId = ScorableId(uuid: aggregateId.id)
            ..name = 'Test Scorable');
          // Check cached DTO
          final scorableDto = await scorekeeper.getCachedAggregateDtoById<ScorableDto>(aggregateId);
          expect(scorableDto, isNotNull);
          expect(scorableDto.name, equals('Test Scorable'));
          expect(scorableDto.aggregateId, equals(aggregateId));
          expect(scorableDto.participants, isEmpty);
          // Add Participant
          final player1 = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player One');
          await scorekeeper.handleCommand(AddParticipant()
              ..scorableId = ScorableId(uuid: aggregateId.id)
              ..participant = player1
          );
          // Check cached DTO (no need to retrieve the instance again...
          expect(scorableDto.participants, isNotEmpty);
          expect(scorableDto.participants, contains(player1));
          // Adding participants shouldn't be possible
          final player2 = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player Two');
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


      /// Scenario: Receive a remote event while handling a local command
      ///  Given a registered and cached aggregate
      ///  Given ScorableCreatedEvent for the aggregate
      ///  When simultaneously
      ///  And a local AddParticipant command is being sent (event should set sequence 1)
      ///  And a remote ParticipantAdded event is received (event is sequence 1)
      ///  Then only one of them will be handled
      ///
      /// The explanation, for now:
      ///  - the remoteEvent listener is faster than our local command handler
      ///  - the remoteEvent's sequence is correct, since we instantiate it using domainEventFactory.local (thus using nextSequence)
      ///  - by the time the local command is being handled, the remote event is already fully processed, so the sequence number is OKAY
      ///  - in case the sequence would be off (local command is being served first), then we'd get an "invalid sequence" exception for the remote event
      test('Receiving external event while handling command', () async {
        final aggregateId = ScorableAggregateId.random();
        await givenAggregateIdRegistered(aggregateId);
        await givenAggregateIdCached(aggregateId);
        await givenScorableCreatedEvent(aggregateId, 'Test Scorable');
        await givenCacheIsUpToDate(aggregateId);
        thenAssertCachedState(aggregateId, (Scorable scorable) => expect(scorable.name, equals('Test Scorable')));
        // Make sure handling the local command takes a while, so the remote event can interfere...
        commandHandler.addHandlerInterceptor((beforeAfter, aggregate, command) async {
          if (command is AddParticipant && command.participant.participantName == 'LOCAL PLAYER' && beforeAfter == 'BEFORE') {
            print('========= SLEEPING');
            sleep(Duration(milliseconds: 10));
            return new Future.delayed(const Duration(milliseconds: 10), () => null);
          }
        });
        // Set up the (conflicting) remote event
        final participant = Participant(participantId: ParticipantId(uuid: 'REMOTE_ID'), participantName: 'REMOTE PLAYER');
        final remoteDomainEvent = domainEventFactory.local(
            aggregateId,
            1,
            ParticipantAdded()
              ..scorableId = aggregateId.scorableId
              ..participant = participant
        );
        // Let's presume adding participant One takes a while...
        await whenSimultaneously(
          // First action: the command (wrapped in when to catch exception)
          () => when(()=> addParticipantCommand(aggregateId.scorableId, ParticipantId(uuid: 'LOCAL_ID'), 'LOCAL PLAYER')),
          // Second action: the remote event (wrapped in when to catch exception)
          () => when(() => receivedRemoteEvent(remoteDomainEvent))
        );
        // Before we went async, the command would have been handled without interrupting for the remote event
        // meaning the remote event would become stale...
        // However, after the switch, the remote event is being handled before the local command...
        await eventually(() =>
            thenEventTypeShouldBeHandledNumberOfTimes(
                aggregateId, ScorableCreated, 1));
        await eventually(() =>
            thenEventTypeShouldBeHandledNumberOfTimes(
                aggregateId, ParticipantAdded, 1));
        await eventually(() => thenNoSystemEventShouldBePublished());
        thenAggregateShouldBeCached(aggregateId);
        // Check if Participant is actually added
        thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
          expect(scorable.participants, isNotNull);
          print('=============== ${scorable.participants}');
          expect(scorable.participants.length, equals(1));
          // expect(scorable.participants[0].name, equals('REMOTE PLAYER'));
          expect(scorable.participants[0].participantName, equals('LOCAL PLAYER'));
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
      /// TODO: is the above explanation still valid? we now embraced the asynchronous nature of command and event handling... we do wait a lot, but that's all optional now, isn't it?
      test('Exception while handling domain event', () async {
        final aggregateId = ScorableAggregateId.random();
        await givenAggregateIdRegistered(aggregateId);
        await givenAggregateIdCached(aggregateId);
        await givenScorableCreatedEvent(aggregateId, 'Test Scorable');
        await givenCacheIsUpToDate(aggregateId);
        // Make sure that the handling of the command results in multiple events,
        // because ALL previously applied events should be undone as well.
        commandHandler.addHandlerInterceptor((beforeAfter, aggregate, command) {
          if ('BEFORE' == beforeAfter && command is AddParticipant) {
            final participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player Two');
            aggregate.apply(ParticipantAdded()
              ..participant = participant);
          }
        });
        // Make sure handling of the applied events of the commands throws an exception
        var mockException = Exception('Some random exception thrown in the event handler');
        eventHandler.addHandlerInterceptor((aggregate, event) {
          if (event.payload is ParticipantAdded &&
              event.payload.participant.name == 'Player One') {
            throw mockException;
          }
        });
        await when(() =>
            addParticipantCommand(
                aggregateId.scorableId, ParticipantId(uuid: 'PARTICIPANT_ID'), 'Player One'));
        await eventually(() => thenExceptionShouldBeThrown(mockException));
        // The first event should be handled (add Player Two), but it should not be stored because of failure adding Player One
        thenEventTypeShouldBeHandledNumberOfTimes(
            aggregateId, ParticipantAdded, 1);
        await thenEventTypeShouldBeStoredNumberOfTimes(
            aggregateId, ParticipantAdded, 0);
        thenNoSystemEventShouldBePublished();
        // Participant cannot be added
        thenAssertCachedState<Scorable>(aggregateId, (Scorable scorable) {
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
        final aggregateId = ScorableAggregateId.random();
        await when(() => createScorableCommand(aggregateId.scorableId, 'Test'));
        thenEventTypeShouldBePublishedNumberOfTimes(aggregateId, ScorableCreated, 1);
      });

      // TODO: failed commands should not result in publication of events

    });

  });

}


