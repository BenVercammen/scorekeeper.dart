
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';


void main() {

  group('DomainEventId', () {

    test('Test local constructor', () {
      final eventId = DomainEventId.local( 0);
      expect(eventId.uuid, isNotNull);
      expect(eventId.sequence, equals(0));
      expect(eventId.timestamp, isNotNull);
    });

    test('Equals method', () {
      final uuid1 = Uuid().v4();
      final uuid2 = Uuid().v4();
      final timestamp1 = DateTime.now();
      final timestamp2 = DateTime.now();
      // Exactly alike
      expect(DomainEventId.of(uuid1, 0, timestamp1), equals(DomainEventId.of(uuid1, 0, timestamp1)));
      // Timestamp is not taken into account
      expect(DomainEventId.of(uuid1, 0, timestamp2), equals(DomainEventId.of(uuid1, 0, timestamp1)));
      // Uuid and sequence are important
      expect(DomainEventId.of(uuid1, 0, timestamp1), isNot(equals(DomainEventId.of(uuid2, 0, timestamp1))));
      expect(DomainEventId.of(uuid1, 0, timestamp1), isNot(equals(DomainEventId.of(uuid1, 1, timestamp1))));
    });

  });

  group('DomainEvent', () {

    test('Equals method', () {
      final eventId1 = DomainEventId.local(0);
      final eventId2 = DomainEventId.local(1);
      final aggregateId1 = AggregateId.random();
      final aggregateId2 = AggregateId.random();
      final aggregateId3 = AggregateId.random();
      final payload1 = ScorableCreated()
        ..name = 'Test'
        ..aggregateId = aggregateId1.id;
      final payload1b = ScorableCreated()
        ..name = 'Test 2'
        ..aggregateId = aggregateId1.id;
      final payload2 = ScorableCreated()
        ..name = 'Test'
        ..aggregateId = aggregateId2.id;
      final payload2b = ScorableCreated()
        ..name = 'Test'
        ..aggregateId = aggregateId2.id;
      final payload3 = ScorableCreatedWithEquals()
        ..name = 'Test'
        ..aggregateId = aggregateId3.id;
      final payload3b = ScorableCreatedWithEquals()
        ..name = 'Test'
        ..aggregateId = aggregateId3.id;
      expect(DomainEvent.of(eventId1, aggregateId1, payload1), equals(DomainEvent.of(eventId1, aggregateId1, payload1)));
      expect(DomainEvent.of(eventId2, aggregateId1, payload1), equals(DomainEvent.of(eventId2, aggregateId1, payload1)));
      expect(DomainEvent.of(eventId2, aggregateId2, payload1), equals(DomainEvent.of(eventId2, aggregateId2, payload1)));
      expect(DomainEvent.of(eventId2, aggregateId2, payload2), equals(DomainEvent.of(eventId2, aggregateId2, payload2)));
      expect(DomainEvent.of(eventId1, aggregateId1, payload1), isNot(equals(DomainEvent.of(eventId1, aggregateId1, payload1b))));
      expect(DomainEvent.of(eventId1, aggregateId1, payload1), isNot(equals(DomainEvent.of(eventId1, aggregateId1, payload2))));
      expect(DomainEvent.of(eventId1, aggregateId1, payload1), isNot(equals(DomainEvent.of(eventId2, aggregateId1, payload1))));
      expect(DomainEvent.of(eventId1, aggregateId1, payload1), isNot(equals(DomainEvent.of(eventId2, aggregateId2, payload1))));
      expect(DomainEvent.of(eventId1, aggregateId2, payload2), isNot(equals(DomainEvent.of(eventId1, aggregateId2, payload1))));
      expect(DomainEvent.of(eventId1, aggregateId1, payload2), isNot(equals(DomainEvent.of(eventId1, aggregateId1, payload1))));
      expect(DomainEvent.of(eventId1, aggregateId1, payload2), isNot(equals(DomainEvent.of(eventId1, aggregateId1, payload1b))));
      expect(DomainEvent.of(eventId1, aggregateId2, payload1), isNot(equals(DomainEvent.of(eventId2, aggregateId2, payload1))));

      // TODO:
      // We don't want to check the identity of the payload, just the content,
      // but we cannot rely on the actual payload class to implement a proper equals method
      expect(DomainEvent.of(eventId2, aggregateId2, payload2), isNot(equals(DomainEvent.of(eventId2, aggregateId2, payload2b))));
      // At the moment, we rely on a proper equals implementation of the DomainEvents payload...
      expect(DomainEvent.of(eventId2, aggregateId3, payload3), equals(DomainEvent.of(eventId2, aggregateId3, payload3b)));
    });

  });

  /// Probably the most important feature, the synchronization between multiple EventManager instances.
  /// If there is only a single (local) EventManager, all data will just remain within the local instance.
  /// But as soon as there are multiple EventManagers, the Events are to be exchanged between all of them.
  /// This means receiving and sending events (Domain, Integration, System) from and to the remote EventManager(s).
  ///
  group('EventManager synchronization', () {

    /// Technical scenario's:
    ///  - DomainEvents published by local EventManager should be received by the remote EventManager
    ///  - DomainEvents published by remote EventManagers should be received by the local EventManager
    ///  TODO: do we need an event backbone?? how can we know for sure

    // TODO: see event_synchronization.feature for functional scenario's

      test('happy flow', () {

      });

      // TODO: test event ID and invalid sequence issues (becomes important when introducing remote event managers)

  });

  group('EventManagerInMemoryImpl', () {

    EventManager eventManager;

    DomainEvent event1;

    DomainEvent event2;

    DomainEvent event2b;

    DomainEvent event2c;

    DomainEvent event3;

    DomainEvent event4;

    AggregateId aggregateId;

    Exception lastThrownException;

    setUp(() {
      eventManager = EventManagerInMemoryImpl();
      aggregateId = AggregateId.random();
      eventManager.registerAggregateId(aggregateId);
      final payload1 = ScorableCreated()
        ..aggregateId = aggregateId.id
        ..name = 'Test';
      event1 = DomainEvent.of(DomainEventId.local(0), aggregateId, payload1);
      final payload2 = ParticipantAdded()
        ..aggregateId = aggregateId.id
        ..participant = Participant();
      event2 = DomainEvent.of(DomainEventId.local(1), aggregateId, payload2);
      final payload3 = ParticipantAdded()
        ..aggregateId = aggregateId.id
        ..participant = Participant();
      event3 = DomainEvent.of(DomainEventId.local(2), aggregateId, payload3);
      final payload4 = ParticipantAdded()
        ..aggregateId = aggregateId.id
        ..participant = Participant();
      event4 = DomainEvent.of(DomainEventId.local(1), aggregateId, payload4);
      // Same aggregate, same sequence, same payload, different UUID, so different origin
      event2b = DomainEvent.of(DomainEventId.local(1), aggregateId, payload2);
      // Same aggregate, same sequence, different payload
      event2c = DomainEvent.of(DomainEventId.local(1), aggregateId, payload3);
    });

    void given(Function() callback) {
      try {
        callback();
        lastThrownException = null;
      } on Exception catch(exception) {
        lastThrownException = exception;
      }
    }

    void receivedEvent(DomainEvent event) {
      eventManager.storeAndPublish(event);
    }

    void thenNoExceptionShouldBeThrown() {
      expect(lastThrownException, isNull);
    }

    /// TODO:
    ///  - storeAndPublish: zien dat het event effectief gepersisteerd wordt + op de stream terecht komt
    ///     - weliswaar enkel als het om een aggregateId gaat waarop we geregistreerd zijn!
    ///  - getEventsForAggregate: zien dat we alle events voor een aggregate kunnen opvragen
    ///  - (un)registerAggregateId(s):

    /// Then a SystemEvent of the given type should be published
    void thenSystemEventShouldBePublished(SystemEvent expectedEvent) {
      expect(eventManager.getSystemEvents().where((actualEvent) {
        if (actualEvent.runtimeType != expectedEvent.runtimeType) {
          return false;
        }
        if (actualEvent is EventNotHandled && expectedEvent is EventNotHandled) {
          return actualEvent.notHandledEventId == expectedEvent.notHandledEventId &&
              actualEvent.reason.contains(expectedEvent.reason);
        }
        return false;
      }).length, equals(1));
    }

    /// Then no SystemEvent should be published
    void thenNoSystemEventShouldBePublished() {
      expect(eventManager.getSystemEvents(), isEmpty);
    }

    /// In case events are added out-of-sync, we should raise a SystemEvent...
    group('Out of sync event sequences', () {

      /// Missing event 3... eventManager should wait and possibly check the remote for event 3
      test('Missing an event in the sequence', () {
        given(() => receivedEvent(event1));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event4));
        thenNoExceptionShouldBeThrown();
        // TODO: mss op aparte queue houden? of verwijderen en remote terug aanroepen?
        thenSystemEventShouldBePublished(EventNotHandled(event4.id, 'Sequence invalid'));
      });

      /// Missing event 3 received after event 4
      test('Receiving missing event in the sequence', () {
        given(() => receivedEvent(event1));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event4));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event3));
        thenNoExceptionShouldBeThrown();
        thenSystemEventShouldBePublished(EventNotHandled(event4.id, 'Sequence invalid'));
        // TODO: then 3 and 4 should be emitted / applied to aggregate !?
        // TODO: what with the LinkedHashSet ordering???
      });

      /// Receiving the same event twice, the duplicate event should just be ignored
      test('Duplicate DomainEvent in the sequence can be ignored', () {
        given(() => receivedEvent(event1));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        thenNoSystemEventShouldBePublished();
        // TODO: then duplicate event should be logged?
      });

      /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
      test('DomainEvent with matching sequence and payload', () {
        given(() => receivedEvent(event1));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2b));
        thenNoExceptionShouldBeThrown();
        thenSystemEventShouldBePublished(EventNotHandled(event2b.id, 'Sequence invalid'));
      });

      /// Receiving the same event sequence twice, all other values alike, the duplicate event should just be ignored
      test('DomainEvent with matching sequence, different payload', () {
        given(() => receivedEvent(event1));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2));
        thenNoExceptionShouldBeThrown();
        given(() => receivedEvent(event2c));
        thenNoExceptionShouldBeThrown();
        thenSystemEventShouldBePublished(EventNotHandled(event2c.id, 'Sequence invalid'));
      });

    });

  });


}

/// Extended event with a proper equals method
/// TODO: perhaps we can also generate this?
///  perhaps we'll have to generate and expose a lot more classes from the (example) domain?
///   - Extended commands and events with equals methods
///   - DTO's that only contain the properties?
///     -> how to prevent the clients to get full control of the aggregates?
class ScorableCreatedWithEquals extends ScorableCreated {

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScorableCreatedWithEquals && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

}