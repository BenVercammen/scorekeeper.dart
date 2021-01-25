
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



    /// TODO:
    ///  - storeAndPublish: zien dat het event effectief gepersisteerd wordt + op de stream terecht komt
    ///     - weliswaar enkel als het om een aggregateId gaat waarop we geregistreerd zijn!
    ///  - getEventsForAggregate: zien dat we alle events voor een aggregate kunnen opvragen
    ///  - (un)registerAggregateId(s):

    /// Then a SystemEvent of the given type should be published



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