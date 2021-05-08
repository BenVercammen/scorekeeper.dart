
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';

/// TODO: https://pub.dev/packages/get_storage
/// TODO: https://pub.dev/packages/shared_preferences
///   => beiden key=value stores
///   is net te weinig voor wat we zouden moeten doen, niet?


class EventStoreSQLiteImpl implements EventStore {
  @override
  int countEventsForAggregate(AggregateId aggregateId) {
    // TODO: implement countEventsForAggregate
    throw UnimplementedError();
  }

  @override
  Stream<DomainEvent<Aggregate>> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp}) {
    // TODO: implement getEventsForAggregate
    throw UnimplementedError();
  }

  @override
  Stream<SystemEvent> getSystemEvents() {
    // TODO: implement getSystemEvents
    throw UnimplementedError();
  }

  @override
  bool hasEventsForAggregate(AggregateId aggregateId) {
    // TODO: implement hasEventsForAggregate
    throw UnimplementedError();
  }

  @override
  void registerAggregateId(AggregateId aggregateId) {
    // TODO: implement registerAggregateId
  }

  @override
  void registerAggregateIds(Iterable<AggregateId> aggregateIds) {
    // TODO: implement registerAggregateIds
  }

  @override
  void storeDomainEvent(DomainEvent<Aggregate> event) {
    // TODO: implement storeDomainEvent
    throw UnimplementedError();
  }

  @override
  void storeSystemEvent(SystemEvent event) {
    // TODO: implement storeSystemEvent
  }

  @override
  void unregisterAggregateId(AggregateId aggregateId) {
    // TODO: implement unregisterAggregateId
  }

}


/// TODO: https://pub.dev/packages/hive
/// Hive:
///   - key=value
///   - objects
///   - eventueel voor AggregateCache alvast interessant
///     -> groot nadeel: @HiveType(typeId: 0)
///       -> dus wel redelijk wat code te genereren op basis van entiteiten?
///       -> en gaat wel wat mapping voor nodig zijn...
///     -> ik wil eigenlijk domain zo "puur" mogelijk houden
///       -> dus een aparte "persistence" layer nodig, waar die HiveTypes in leven
///         -> en die er dus NIET uit leaken!
///         -> mogelijk, maar tricky?

/// TODO: https://pub.dev/packages/sqflite
///   -> overkill voor een event store?
///   -> voordeel zou kunnen zijn dat we hier makkelijker queries mee kunnen draaien,
///       MAAR eigenlijk is het bij ES+CQRS niet meteen de bedoeling om veel queries te maken
///       -> indien bepaalde view nodig, event stream doorlopen en op basis daarvan antwoorden geven?
///   ->