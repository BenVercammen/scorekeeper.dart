
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';

// Import the generated part of moor...
part 'event_store_moor.g.dart';

/// Tell moor to prepare a database class that uses the defined table(s).
@UseMoor(tables: [DomainEventTable, RegisteredAggregateTable])
class EventStoreMoorImpl extends _$EventStoreMoorImpl implements EventStore {

  EventStoreMoorImpl() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  Future<int> countEventsForAggregate(AggregateId aggregateId) async {
    var countExp = domainEventTable.aggregateId.count();
    final query = selectOnly(domainEventTable)
      ..addColumns([countExp])
      ..where(domainEventTable.aggregateId.equals(aggregateId.id));
    final count = await query.map((row) => row.read(countExp)).getSingle();
    return count;
  }

  @override
  Stream<DomainEvent<Aggregate>> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp}) async* {
    // TODO: WHERE toevoegen afhankelijk van params
    final list = await select(domainEventTable).get();
    for (final event in list) {
      yield DomainEvent(eventId: event.eventId,
      timestamp: event.timestamp,
          producerId: event.producerId,
          applicationVersion: event.applicationVersion,
          domainId: event.domainId,
          domainVersion: event.domainVersion,
          payload: event.payload,
          aggregateId: AggregateId.of(event.aggregateId),
          sequence: event.sequence);
    }
  }

  @override
  Stream<SystemEvent> getSystemEvents() {
    // TODO: implement getSystemEvents
    throw UnimplementedError();
  }

  @override
  Future<bool> hasEventsForAggregate(AggregateId aggregateId) async {
    return await countEventsForAggregate(aggregateId) > 0;
  }

  @override
  Future<void> registerAggregateId(AggregateId aggregateId) async {
    await into(registeredAggregateTable).insert(RegisteredAggregateData(
        timestamp: DateTime.now(), aggregateId: aggregateId.id));
  }

  @override
  Future<void> registerAggregateIds(Iterable<AggregateId> aggregateIds) {
    // TODO: implement registerAggregateIds
    throw UnimplementedError();
  }

  @override
  Future<void> storeDomainEvent(DomainEvent<Aggregate> event) async {
    await into(domainEventTable).insert(DomainEventData(
        eventId: event.eventId,
        timestamp: event.timestamp,
        userId: event.userId,
        processId: event.processId,
        producerId: event.producerId,
        applicationVersion: event.applicationVersion,
        domainId: event.domainId,
        domainVersion: event.domainVersion,
        aggregateId: event.aggregateId.id,
        sequence: event.sequence,
        // TODO: serializer???
        payload: event.payload.toString()));
  }

  @override
  Future<void> storeSystemEvent(SystemEvent event) {
    // TODO: implement storeSystemEvent
    throw UnimplementedError();
  }

  @override
  Future<void> unregisterAggregateId(AggregateId aggregateId) async {
    await delete(registeredAggregateTable)..where((a) => a.aggregateId.equals(aggregateId.id))..go();
  }

  @override
  Future<void> clear() async {
    await delete(domainEventTable).go();
  }

  @override
  Future<bool> isRegisteredAggregateId(AggregateId aggregateId) async {
    final aggregate = select(registeredAggregateTable)
      ..where((a) => a.aggregateId.equals(aggregateId.id))
      ..watchSingle();
    return null != await aggregate.getSingleOrNull();
  }

}


/// The method to open a connection to the event store (.sqlite file)
LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    // await Directory(dbFolder.path).create(recursive: true);
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}


/// The "DomainEvent" table, containing domain events for registered Aggregates
@DataClassName('DomainEventData')
class DomainEventTable extends Table {
  TextColumn get eventId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get userId => text().withLength(min: 36, max: 36).nullable()();
  TextColumn get processId => text().withLength(min: 36, max: 36).nullable()();
  TextColumn get producerId => text().withLength(min: 36, max: 36)();
  TextColumn get applicationVersion => text().withLength(min: 1, max: 36)();
  TextColumn get domainId => text().withLength(min: 36, max: 36)();
  TextColumn get domainVersion => text().withLength(min: 1, max: 36)();
  TextColumn get aggregateId => text().withLength(min: 36, max: 36)();
  IntColumn get sequence => integer()();
  TextColumn get payload => text()();
}

/// The "AggregateId" table, to keep track of Aggregates for which events should be stored
@DataClassName('RegisteredAggregateData')
class RegisteredAggregateTable extends Table {
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get aggregateId => text().withLength(min: 36, max: 36)();
}
