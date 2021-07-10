
import 'dart:convert';
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

  final DomainSerializer domainSerializer;

  final DomainDeserializer domainDeserializer;

  final bool allowClear;

  EventStoreMoorImpl(
      this.domainSerializer,
      this.domainDeserializer,
      {Future<Directory>? dbFileDir, String dbFilename = 'db.sqlite', this.allowClear = false})
      : super(_openConnection(dbFileDir: dbFileDir, dbFilename: dbFilename));

  @override
  int get schemaVersion => 1;

  @override
  Future<int> countEventsForAggregate(AggregateId aggregateId) async {
    final countCol = countAll(filter: domainEventTable.aggregateId.equals(aggregateId.id));
    final query = selectOnly(domainEventTable)..addColumns([countCol]);
    return await query.map((row) => row.read(countCol)).getSingle();
  }

  @override
  Stream<DomainEvent> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp}) async* {
    final query = select(domainEventTable);
    if (aggregateId != null) {
      query.where((e) => e.aggregateId.equals(aggregateId.id));
    }
    if (timestamp != null) {
      query.where((e) => e.timestamp.isBiggerOrEqualValue(timestamp));
    }

    final list = await query.get();
    for (final event in list) {
      final payload = domainDeserializer.deserialize(event.payloadType, event.payload);
      yield DomainEvent(
          eventId: event.eventId,
          timestamp: event.timestamp,
          producerId: event.producerId,
          applicationVersion: event.applicationVersion,
          domainId: event.domainId,
          domainVersion: event.domainVersion,
          payloadType: event.payloadType,
          payload: payload,
          // TODO: lijkt alsof deze nog niet getest werd? Pas in flutter UI probleem naar boven gekomen...
          aggregateId: domainDeserializer.deserializeAggregateId(event.aggregateId, event.aggregateType),
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
    if (await isRegisteredAggregateId(aggregateId)) {
      // TODO: warn!? Error!?
      return;
    }
    await into(registeredAggregateTable).insert(RegisteredAggregateData(
      aggregateId: aggregateId.id,
      aggregateType: aggregateId.type.toString(),
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> registerAggregateIds(Iterable<AggregateId> aggregateIds) async {
    await Future.sync(() => aggregateIds.forEach(registerAggregateId));
  }

  @override
  Future<void> storeDomainEvent(DomainEvent event) async {
    await validateDomainEvent(event);
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
        aggregateType: event.aggregateId.type.toString(),
        sequence: event.sequence,
        payloadType: event.payloadType,
        payload: domainSerializer.serialize(event.payload)
    ));
  }

  @override
  Future<void> storeSystemEvent(SystemEvent event) {
    // TODO: implement storeSystemEvent
    throw UnimplementedError();
  }

  @override
  Future<void> unregisterAggregateId(AggregateId aggregateId) async {
    final deleteStatement = delete(registeredAggregateTable)
      ..where((a) => a.aggregateId.equals(aggregateId.id));
    await deleteStatement.go();
  }

  @override
  Future<void> clear() async {
    if (!allowClear) {
      throw Exception('Not allowed to clear all events from event store!');
    }
    await delete(registeredAggregateTable).go();
    await delete(domainEventTable).go();
  }

  @override
  Future<bool> isRegisteredAggregateId(AggregateId aggregateId) async {
    final aggregate = select(registeredAggregateTable)
      ..where((a) => a.aggregateId.equals(aggregateId.id))
      ..watchSingle();
    final aggregateData = await aggregate.getSingleOrNull();
    return null != aggregateData;
  }

  @override
  Future<int> nextSequenceForAggregate(AggregateId aggregateId) async {
    final max = domainEventTable.sequence.max();
    final query = selectOnly(domainEventTable)
      ..where(domainEventTable.aggregateId.equals(aggregateId.id))
      ..addColumns([max]);
    return await query.map((row) => row.read(max)).getSingle() ?? 0;
  }

  /// TODO: duplicate! apart trekken somehow..
  @override
  Future<void> validateDomainEvent(DomainEvent event) async {
    if (event.sequence < 0) {
      throw InvalidEventException(event, 'Invalid sequence');
    }
    // If the aggregateId is not yet registered, throw an exception
    // (yes, Aggregates need to be registered explicitly)
    if (! await isRegisteredAggregateId(event.aggregateId)) {
      throw InvalidEventException(event, 'AggregateId not registered');
    }
    await _checkDomainEventExists(event);
    // EventId should be unique
    await _checkUniqueEventId(event);
    // Also check if the sequence is valid / unique
    await _domainEventSequenceInvalid(event);
  }

  /// TODO: duplicate! apart trekken somehow..
  /// Make sure that there is only one event in the entiry event store with the given EventId
  /// TODO: hmm, this is quite a heavy operation... digging through all aggregates and their events...
  Future<void> _checkUniqueEventId(DomainEvent event) async {
    await getDomainEvents().forEach((aggregateEvent) {
      if (aggregateEvent.eventId == event.eventId) {
        throw InvalidEventException(event, 'Non-identical event with the same ID already stored in EventStore');
      }
    });
  }

  /// TODO: duplicate! apart trekken somehow..
  /// Check if the DomainEvent sequence is OK.
  /// Currently, this means no other event with the given sequence
  Future<void> _domainEventSequenceInvalid(DomainEvent event) async {
    final nextSequence = await nextSequenceForAggregate(event.aggregateId);
    if (nextSequence != event.sequence) {
      throw InvalidEventException(event, 'Sequence invalid: expected $nextSequence but was ${event.sequence}');
    }
  }

  /// TODO: duplicate! apart trekken somehow..
  /// Check if the DomainEvent is already persisted
  /// We ignore the actual payload, as soon as EventId, AggregateId and sequence match,
  /// we presume the entire DomainEvent matches.
  Future<void> _checkDomainEventExists(DomainEvent domainEvent) async {
    final storedAggregateEvents = getDomainEvents(aggregateId: domainEvent.aggregateId);
    final matches = await storedAggregateEvents.where((event) {
      return event.eventId == domainEvent.eventId && event.aggregateId == event.aggregateId;
    }).toList();
    if (matches.isNotEmpty) {
      throw InvalidEventException(domainEvent, 'Event already stored');
    }
  }

  @override
  Stream<AggregateId> registeredAggregateIds() async* {
    // TODO: is geen stream he, kan nog problemen opleveren, niet?
    final list = await select(registeredAggregateTable).get();
    for (final aggregate in list) {
      yield domainDeserializer.deserializeAggregateId(aggregate.aggregateId, aggregate.aggregateType);
    }
  }

}

/// The method to open a connection to the event store (.sqlite file)
LazyDatabase _openConnection({Future<Directory>? dbFileDir, String dbFilename = 'db.sqlite'}) {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await (dbFileDir ?? getApplicationDocumentsDirectory());
    // await Directory(dbFolder.path).create(recursive: true);
    final file = File(p.join(dbFolder.path, dbFilename));
    return VmDatabase(file);
  });
}


/// The "DomainEvent" table, containing domain events for registered Aggregates
@DataClassName('DomainEventData')
class DomainEventTable extends Table {

  @override
  Set<Column> get primaryKey => {eventId};

  TextColumn get eventId => text().withLength(min: 36, max: 36)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get userId => text().withLength(min: 36, max: 36).nullable()();
  TextColumn get processId => text().withLength(min: 36, max: 36).nullable()();
  TextColumn get producerId => text().withLength(min: 6, max: 36)();
  TextColumn get applicationVersion => text().withLength(min: 1, max: 36)();
  TextColumn get domainId => text().withLength(min: 6, max: 36)();
  TextColumn get domainVersion => text().withLength(min: 1, max: 36)();
  TextColumn get aggregateId => text().withLength(min: 36, max: 36)();
  TextColumn get aggregateType => text().withLength(min: 1, max: 64)();
  IntColumn get sequence => integer()();
  TextColumn get payloadType => text()();
  TextColumn get payload => text()();
}

/// The "AggregateId" table, to keep track of Aggregates for which events should be stored
@DataClassName('RegisteredAggregateData')
class RegisteredAggregateTable extends Table {

  @override
  Set<Column> get primaryKey => {aggregateId};

  /// The UUID of the AggregateId
  TextColumn get aggregateId => text().withLength(min: 36, max: 36)();

  /// The Type of the Aggregate to which the Id points
  /// Required in order to instantiate the correct AggregateId subclass
  TextColumn get aggregateType => text().withLength(min: 1, max: 48)();

  /// TODO: other metadata...
  DateTimeColumn get timestamp => dateTime()();
}
