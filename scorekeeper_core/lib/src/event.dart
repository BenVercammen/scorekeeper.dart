import 'dart:async';
import 'dart:collection';

import 'package:scorekeeper_domain/core.dart';

/// The EventManager is responsible for the following:
///  - persist all events that were published by the Scorekeeper instance
///  - persist all events coming in from another EventManager
///  - publish all events to another EventManager
///  - ...
///
abstract class EventManager {

  /// Publish a single DomainEvent.
  /// Should store the event and emit it through the [#eventStream] method
  void storeAndPublish(DomainEvent event);

  /// Get all events for a single aggregate
  Set<DomainEvent> getEventsForAggregate(AggregateId aggregateId);

  /// Get a Stream of DomainEvents received by the EventManager.
  /// These events come either from the own Scorekeeper instance,
  /// or through the remote one ....
  Stream<DomainEvent> get domainEventStream;

  /// Get all system events
  Set<SystemEvent> getSystemEvents();

  /// Get a Stream of SystemEvents received by the EventManager.
  /// These events come either from the own Scorekeeper instance,
  /// or through the remote one ....
  Stream<SystemEvent> get systemEventStream;

  void registerAggregateId(AggregateId aggregateId);

  void registerAggregateIds(Iterable<AggregateId> aggregateIds);

  void unregisterAggregateId(AggregateId aggregateId);

  bool hasEventsForAggregate(AggregateId aggregateId);

  // /// Get the last EventId that was stored for the given aggregate
  // EventId getLastAppliedEventIdForAggregate(AggregateId aggregateId);
  //
  // /// Check if the given DomainEvent is the actual "initial event".
  // /// An initial event is the event that is responsible for instantiating an Aggregate
  // ///  TODO: nu heel veel gedoe daaromtrent, kunnen we Events nie gewoon markeren? Of registreren als zijnde "initial events"?
  // ///  zodanig dat we heel dit gedoe niet nodig hebben???
  // bool isInitialAggregateDomainEvent(DomainEvent<Aggregate> domainEvent) {
  //
  // }

}

/// In memory implementation of the EventManager
///
class EventManagerInMemoryImpl implements EventManager {

  /// Important to use a LinkedHashSet in order to preserve the insertion order!
  final Map<AggregateId, LinkedHashSet<DomainEvent>> _domainEventStore = HashMap();

  final Set<SystemEvent> _systemEventStore = <SystemEvent>{};

  final StreamController<DomainEvent> _domainEventController = StreamController<DomainEvent>();

  final StreamController<SystemEvent> _systemEventController = StreamController<SystemEvent>();

  final Set<AggregateId> _registeredAggregateIds = <AggregateId>{};

  @override
  void storeAndPublish(DomainEvent event) {
    // Ignore this event. We only store events for the registered aggregates, the others will need to be pulled from the remote event manager
    if (!_registeredAggregateIds.contains(event.aggregateId)) {
      return;
    }
    _domainEventStore.putIfAbsent(event.aggregateId, () => LinkedHashSet<DomainEvent>());
    if (!_domainEventStore[event.aggregateId].contains(event)) {
      _domainEventStore[event.aggregateId].add(event);
      _domainEventController.add(event);
    }
  }

  @override
  Stream<DomainEvent> get domainEventStream => _domainEventController.stream.asBroadcastStream();

  @override
  Stream<SystemEvent> get systemEventStream => _systemEventController.stream.asBroadcastStream();

  @override
  Set<DomainEvent> getEventsForAggregate(AggregateId aggregateId) {
    return _domainEventStore[aggregateId] ?? <DomainEvent>{};
  }

  @override
  Set<SystemEvent> getSystemEvents() {
    return Set<SystemEvent>.from(_systemEventStore);
  }

  @override
  void registerAggregateId(AggregateId aggregateId) {
    _registeredAggregateIds.add(aggregateId);
  }

  @override
  void registerAggregateIds(Iterable<AggregateId> aggregateIds) {
    _registeredAggregateIds.addAll(aggregateIds);
  }

  @override
  void unregisterAggregateId(AggregateId aggregateId) {
    _registeredAggregateIds.remove(aggregateId);
  }

  @override
  bool hasEventsForAggregate(AggregateId aggregateId) {
    return _domainEventStore.containsKey(aggregateId);
  }

  @override
  EventId getLastAppliedEventIdForAggregate(AggregateId aggregateId) {
    return _domainEventStore.containsKey(aggregateId) ? _domainEventStore[aggregateId].last.id : null;
  }
}
