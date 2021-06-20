import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_event_store_moor/src/event_store_moor.dart';
import 'package:test/test.dart';

import 'package:path/path.dart' as p;

import 'generated/events.pb.dart';
import 'test_domain_event.dart';

/// In order to store the .sqlite file some place else,
/// we'll be using the temporary directory
final tempTestDatabase = LazyDatabase(() async {
  final dbFolder = await getTemporaryDirectory();
  final file = File(p.join(dbFolder.path, 'db.sqlite'));
  // TODO: bestand toch maar wegsmijten aan het begin van test run, zeker indien database schema nog vaak wijzigt..
  print('DB FILE located in ${file.absolute.path}');
  return VmDatabase(file);
});

class TestEventStoreMoorImpl extends EventStoreMoorImpl {
  TestEventStoreMoorImpl() : super(
    TestDomainEventSerializer(),
    TestDomainEventDeserializer(),
    tempTestDatabase
  );

  @override
  Future<void> clear() async {
    await delete(domainEventTable).go();
    await delete(registeredAggregateTable).go();
  }
}

/// We test specific implementation of the EventStoreMoorImpl class.
void main() {
  const domainEventFactory =
      DomainEventFactory(producerId: 'test', applicationVersion: 'test');
  final EventStore eventStore = TestEventStoreMoorImpl();

  setUp(() async {
    await eventStore.clear();
  });

  tearDown(() async {
    await eventStore.clear();
  });

  group('RegisteredAggregateId', () {
    test("Write + read registered AggregateId's", () async {
      final aggregateId = AggregateId.random(Aggregate);
      final aggregateId2 = AggregateId.random(Aggregate);
      expect(await eventStore.isRegisteredAggregateId(aggregateId), equals(false));
      expect(await eventStore.isRegisteredAggregateId(aggregateId2), equals(false));
      await eventStore.registerAggregateId(aggregateId);
      await eventStore.registerAggregateId(aggregateId);
      expect(await eventStore.isRegisteredAggregateId(aggregateId), equals(true));
      expect(await eventStore.isRegisteredAggregateId(aggregateId2), equals(false));
      await eventStore.registerAggregateId(aggregateId2);
      expect(await eventStore.isRegisteredAggregateId(aggregateId), equals(true));
      expect(await eventStore.isRegisteredAggregateId(aggregateId2), equals(true));
    });

    test('AggregateId can only be registered once', () async {
      final aggregateId = AggregateId.random(Aggregate);
      await eventStore.registerAggregateId(aggregateId);
      try {
        await eventStore.registerAggregateId(aggregateId);
        fail('AggregateId can only be registered once!');
      } on Exception catch(e) {
        expect(e.toString(), contains('bblabla'));
      }
    });

    test('Is registered AggregateId', () async {
      final aggregateId = AggregateId.random(Aggregate);
      expect(await eventStore.isRegisteredAggregateId(aggregateId), equals(false));
      await eventStore.registerAggregateId(aggregateId);
      expect(await eventStore.isRegisteredAggregateId(aggregateId), equals(true));
    });
  });

  group('DomainEvent', () {
    test('Write + read DomainEvent', () async {
      final aggregateId1 = AggregateId.random(Aggregate);
      final domainEventToStore = domainEventFactory.local(
        aggregateId1,
        0,
        'payload',
      );
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.storeDomainEvent(domainEventToStore);
      final loaded = await eventStore.getDomainEvents().toList();
      expect(loaded.length, equals(1));
      expect(loaded.first, equals(domainEventToStore));
    });

    test('Write + read DomainEvent with non-string payload', () async {
      final aggregateId1 = AggregateId.random(Aggregate);
      final domainEventToStore = domainEventFactory.local(
        aggregateId1,
        0,
        TestAggregateCreated(metadata: EventMetadata(eventId: '1'), testAggregateId: aggregateId1.id, contestName: 'test')
      );
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.storeDomainEvent(domainEventToStore);
      final loaded = await eventStore.getDomainEvents().toList();
      expect(loaded.length, equals(1));
      expect(loaded.first, equals(domainEventToStore));
    });

    test('Count DomainEvents for Aggregate', () async {
      final aggregateId1 = AggregateId.random(Aggregate);
      final aggregateId2 = AggregateId.random(Aggregate);
      expect(await eventStore.countEventsForAggregate(aggregateId1), equals(0));
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.registerAggregateId(aggregateId2);
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId1, 0, 'payload'));
      expect(await eventStore.getDomainEvents(aggregateId: aggregateId1).length, equals(1));
      expect(await eventStore.countEventsForAggregate(aggregateId1), equals(1));
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId1, 1, 'payload'));
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId2, 0, 'payload'));
      expect(await eventStore.countEventsForAggregate(aggregateId1), equals(2));
      expect(await eventStore.countEventsForAggregate(aggregateId2), equals(1));
    });

    test('nextSequenceForAggregate', () async {
      final aggregateId1 = AggregateId.random(Aggregate);
      final aggregateId2 = AggregateId.random(Aggregate);
      expect(await eventStore.nextSequenceForAggregate(aggregateId1), equals(0));
      expect(await eventStore.nextSequenceForAggregate(aggregateId2), equals(0));
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.registerAggregateId(aggregateId2);
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId1, 0, 'payload'));
      expect(await eventStore.nextSequenceForAggregate(aggregateId1), equals(1));
      expect(await eventStore.nextSequenceForAggregate(aggregateId2), equals(0));
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId1, 1, 'payload'));
      expect(await eventStore.nextSequenceForAggregate(aggregateId1), equals(2));
      expect(await eventStore.nextSequenceForAggregate(aggregateId2), equals(0));
      await eventStore.storeDomainEvent(domainEventFactory.local(aggregateId2, 0, 'payload'));
      expect(await eventStore.nextSequenceForAggregate(aggregateId1), equals(2));
      expect(await eventStore.nextSequenceForAggregate(aggregateId2), equals(1));
    });
  });
}
