
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';



class TestAggregate extends Aggregate {
  late String name;
  TestAggregate(AggregateId aggregateId) : super(aggregateId);
}

class TestAggregateCreated {
  late String name;
  late String scorableId;
}

void main() {

  final domainEventFactory = DomainEventFactory(producerId: 'test', applicationVersion: 'appVersion');

  group('DomainEvent', () {

    test('Test local DomainEvent factory method', () {
      final event = domainEventFactory.local(AggregateId.random(TestAggregate), 0, 'payload');
      expect(event.eventId, isNotNull);
      expect(event.sequence, equals(0));
      expect(event.timestamp, isNotNull);
      expect(event.aggregateId, isNotNull);
      expect(event.aggregateType, isNotNull);
      expect(event.aggregateType, equals(TestAggregate));
    });

    /// DomainEvents should equal only if eventId and sequence match.
    /// We don't care for timestamp, payload or anything else
    /// TODO: don't we???
    test('Equals method pt1', () {
      final uuid1 = Uuid().v4();
      final uuid2 = Uuid().v4();
      final timestamp1 = DateTime.now().subtract(Duration(microseconds: 5));
      final timestamp2 = DateTime.now();
      // Exactly alike
      expect(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload'), equals(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload')));
      // Timestamp is not taken into account
      expect(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp2, 'payload'), equals(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload')));
      // Uuid and sequence are important
      expect(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload'), isNot(equals(domainEventFactory.remote(uuid2, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload'))));
      expect(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 0, timestamp1, 'payload'), isNot(equals(domainEventFactory.remote(uuid1, AggregateId.of('1', TestAggregate), 1, timestamp1, 'payload'))));
    });

    test('Equals method pt2', () {
      final eventId1 = '0';
      final eventId2 = '1';
      final aggregateId1 = AggregateId.random(TestAggregate);
      final aggregateId2 = AggregateId.random(TestAggregate);
      final aggregateId3 = AggregateId.random(TestAggregate);
      final payload1 = TestAggregateCreated()
        ..name = 'Test'
        ..scorableId = aggregateId1.id;
      final payload1b = TestAggregateCreated()
        ..name = 'Test 2'
        ..scorableId = aggregateId1.id;
      final payload2 = TestAggregateCreated()
        ..name = 'Test'
        ..scorableId = aggregateId2.id;
      final payload2b = TestAggregateCreated()
        ..name = 'Test'
        ..scorableId = aggregateId2.id;
      final payload3 = TestAggregateCreatedWithEquals()
        ..name = 'Test'
        ..scorableId = aggregateId3.id;
      final payload3b = TestAggregateCreatedWithEquals()
        ..name = 'Test'
        ..scorableId = aggregateId3.id;
      final now = DateTime.now();
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1), equals(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1)));
      expect(domainEventFactory.remote(eventId2, aggregateId1, 0, now, payload1), equals(domainEventFactory.remote(eventId2, aggregateId1, 0, now, payload1)));
      expect(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload1), equals(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload1)));
      expect(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload2), equals(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload2)));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1), isNot(equals(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1b))));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1), isNot(equals(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload2))));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1), isNot(equals(domainEventFactory.remote(eventId2, aggregateId1, 0, now, payload1))));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1), isNot(equals(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload1))));
      expect(domainEventFactory.remote(eventId1, aggregateId2, 0, now, payload2), isNot(equals(domainEventFactory.remote(eventId1, aggregateId2, 0, now, payload1))));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload2), isNot(equals(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1))));
      expect(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload2), isNot(equals(domainEventFactory.remote(eventId1, aggregateId1, 0, now, payload1b))));
      expect(domainEventFactory.remote(eventId1, aggregateId2, 0, now, payload1), isNot(equals(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload1))));

      // TODO:
      // We don't want to check the identity of the payload, just the content,
      // but we cannot rely on the actual payload class to implement a proper equals method
      expect(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload2), isNot(equals(domainEventFactory.remote(eventId2, aggregateId2, 0, now, payload2b))));
      // At the moment, we rely on a proper equals implementation of the DomainEvents payload...
      expect(domainEventFactory.remote(eventId2, aggregateId3, 0, now, payload3), equals(domainEventFactory.remote(eventId2, aggregateId3, 0, now, payload3b)));
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
class TestAggregateCreatedWithEquals {

  final TestAggregateCreated _scorableCreated = TestAggregateCreated();

  @override
  bool operator ==(Object other) =>
      identical(this._scorableCreated, other) || other is TestAggregateCreatedWithEquals && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  TestAggregateCreatedWithEquals();

  set name(String name) {
    _scorableCreated.name = name;
  }

  set scorableId(String scorableId) {
    _scorableCreated.scorableId = scorableId;
  }
}
