
import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';


void main() {

  group('DomainEventId', () {

    test('Test local constructor', () {
      final eventId = DomainEventId.local( 0);
      expect(eventId.uuid, isNotNull);
      expect(eventId.sequence, equals(0));
      expect(eventId.timestamp, isNotNull);
    });

  });



  /// TODO: EventManager ook goed testen, zien dat events en aggregates apart gecleared/gemanaged moeten worden!


  group('EventHandlerInMemoryImpl', () {
    group('storeAndPublish', () {
      test('happy flow', () {
        /// TODO:
        ///  - storeAndPublish: zien dat het event effectief gepersisteerd wordt + op de stream terecht komt
        ///     - weliswaar enkel als het om een aggregateId gaat waarop we geregistreerd zijn!
        ///  - getEventsForAggregate: zien dat we alle events voor een aggregate kunnen opvragen
        ///  - (un)registerAggregateId(s):
      });

      // TODO: test event ID and invalid sequence issues (becomes important when introducing remote event managers)

    });
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


