

import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_eventstore_moor/event_store_moor.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// We test specific implementation of the EventStoreMoorImpl class.
void main() {

  late DomainEventFactory domainEventFactory;
  late EventStore eventStore;

  final aggregateId1 = AggregateId.of('101');
  final aggregateId2 = AggregateId.of('102');
  final aggregateId3 = AggregateId.of('103');
  const eventId1 = 'eventId1';

  setUp(() async {
    eventStore = EventStoreMoorImpl();
    await eventStore.clear();
  });

  group('RegisteredAggregateId', () {
    test("Write + read registered AggregateId's", () async {
      final aggregateId = AggregateId.random();
      expect(
          await eventStore.isRegisteredAggregateId(aggregateId), equals(false));
      await eventStore.registerAggregateId(aggregateId);
      final loaded = await eventStore.isRegisteredAggregateId(aggregateId);
      expect(loaded, equals(true));
    });

    test("Count registered AggregateId's", () async {
      final aggregateId = AggregateId.random();
      expect(
          await eventStore.countEventsForAggregate(aggregateId), equals(0));
      await eventStore.registerAggregateId(aggregateId);
      expect(
          await eventStore.countEventsForAggregate(aggregateId), equals(1));
    });
  });

  group('DomainEvent', () {
    test('Write + read DomainEvent', () async {
      final domainEventToStore = DomainEvent(
              eventId: const Uuid().v4(),
              timestamp: DateTime.now(),
              producerId: const Uuid().v4(),
              applicationVersion: 'applicationVersion',
              domainId: const Uuid().v4(),
              domainVersion: 'domainVersion',
              payload: 'payload',
              aggregateId: AggregateId.random(),
              sequence: 1);
      await eventStore.storeDomainEvent(
          domainEventToStore);
      final loaded = await eventStore.getDomainEvents().toList();
      expect(loaded.length, equals(1));
      expect(loaded.first, equals(domainEventToStore));
    });

  });

}