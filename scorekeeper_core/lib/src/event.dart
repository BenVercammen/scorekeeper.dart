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

  /// Get the number of events for a single aggregate
  int countEventsForAggregate(AggregateId aggregateId);

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
      // Also check if the sequence is unique (TODO: and possibly in order...)
      if (_domainEventSequenceInvalid(event.aggregateId, event.id.sequence)) {
        // Store the event, but don't publish!?
        _domainEventStore[event.aggregateId].add(event);
        var systemEvent = EventNotHandled(SystemEventId.local(), event.id, 'Sequence invalid');
        _systemEventStore.add(systemEvent);
        _systemEventController.add(systemEvent);
      } else {
        _domainEventStore[event.aggregateId].add(event);
        _domainEventController.add(event);
      }
    }
  }

  /// Check if the DomainEvent sequence is OK.
  /// Currently, this means no other event with the given sequence
  bool _domainEventSequenceInvalid(AggregateId aggregateId, int sequence) {
    return _domainEventStore[aggregateId].where((event) => event.id.sequence == sequence).isNotEmpty;
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
  int countEventsForAggregate(AggregateId aggregateId) {
    if (_domainEventStore.containsKey(aggregateId)) {
      return _domainEventStore[aggregateId].length;
    }
    return 0;
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
    _domainEventStore.removeWhere((key, value) => key == aggregateId);
  }

  @override
  bool hasEventsForAggregate(AggregateId aggregateId) {
    return _domainEventStore.containsKey(aggregateId);
  }

}
