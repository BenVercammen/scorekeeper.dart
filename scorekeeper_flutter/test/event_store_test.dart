
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_flutter/src/event_store_moor.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {

  late DomainEventFactory domainEventFactory;
  late EventStore eventStore;

  final aggregateId1 = AggregateId.of('101');
  final aggregateId2 = AggregateId.of('102');
  final aggregateId3 = AggregateId.of('103');
  const eventId1 = 'eventId1';
  // final ts1 = DateTime.now().subtract(Duration(minutes: 5));
  // final ts2 = DateTime.now().subtract(Duration(minutes: 4));
  // final ts3 = DateTime.now().subtract(Duration(minutes: 3));
  // final ts4 = DateTime.now().subtract(Duration(minutes: 2));

  setUp(() async {
    // TODO: clean up: delete all existing events!
    // TODO: moet na ELKE test he...
    eventStore = EventStoreMoorImpl();
  });

  group('Standalone test', () {

    test('Write + read', () async {

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
    });

  });


  group('WRITE', () {
    test('storeEvent', () async {
      domainEventFactory = const DomainEventFactory(
          producerId: 'prodId', applicationVersion: 'appVersion');
      // eventStore = await EventStoreSQLiteImpl().init();
      eventStore = EventStoreInMemoryImpl();
      print(eventStore);
      // Register Aggregates so the events are being stored
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.registerAggregateId(aggregateId2);
      await eventStore.registerAggregateId(aggregateId3);

      final domainEvent1 = domainEventFactory.remote(
          eventId1, aggregateId1, 0, DateTime.now(), 'payload');
      await eventStore.storeDomainEvent(domainEvent1);
    });

  });

}