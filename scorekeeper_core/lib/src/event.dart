import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_domain/core.dart';

/// The EventStore is responsible for persisting DomainEvents.
abstract class EventStore {

  /// Store the given DomainEvent.
  /// Returns whether or not the event was stored successfully.
  bool store(DomainEvent event);

  /// Get all events for a single aggregate
  Set<DomainEvent> getEventsForAggregate(AggregateId aggregateId);

  /// Get the number of events for a single aggregate
  int countEventsForAggregate(AggregateId aggregateId);

  /// Get all domain events that are stored within
  Set<DomainEvent> getAllDomainEvents();

  /// Get all system events
  Set<SystemEvent> getSystemEvents();

  void registerAggregateId(AggregateId aggregateId);

  void registerAggregateIds(Iterable<AggregateId> aggregateIds);

  void unregisterAggregateId(AggregateId aggregateId);

  bool hasEventsForAggregate(AggregateId aggregateId);

}

/// Exception to be thrown in case an invalid Event is being stored or handled.
class InvalidEventException implements Exception {

  final DomainEvent event;

  InvalidEventException(this.event);

}

/// In memory implementation of the EventStore
///
class EventStoreInMemoryImpl implements EventStore {

  Logger _logger;

  /// Important to use a LinkedHashSet in order to preserve the insertion order!
  final Map<AggregateId, LinkedHashSet<DomainEvent>> _domainEventStore = HashMap();

  final Set<SystemEvent> _systemEventStore = <SystemEvent>{};

  final Set<AggregateId> _registeredAggregateIds = <AggregateId>{};

  EventStoreInMemoryImpl([this._logger]) {
    _logger ??= Logger();
  }

  @override
  bool store(DomainEvent event) {
    // Ignore this event. We only store events for the registered aggregates, the others will need to be pulled from the remote event manager
    if (!_registeredAggregateIds.contains(event.aggregateId)) {
      return false;
    }
    _domainEventStore.putIfAbsent(event.aggregateId, () => LinkedHashSet<DomainEvent>());
    if (_domainEventExists(event)) {
      _logger.i('Received and ignored duplicate $event');
      return false;
    }
    // Also check if the sequence is unique
    if (_domainEventSequenceInvalid(event.aggregateId, event.id.sequence)) {
      throw InvalidEventException(event);
    }
    _domainEventStore[event.aggregateId].add(event);
    return true;
  }

  /// Check if the DomainEvent sequence is OK.
  /// Currently, this means no other event with the given sequence
  bool _domainEventSequenceInvalid(AggregateId aggregateId, int sequence) {
    // TODO: because of "memory limitations", we'll not be able to actually loop over ALL the events... probably...
    // We'll need to work with snapshots etc...
    return _domainEventStore[aggregateId].where((event) {
      return event.id.sequence == sequence;
    }).isNotEmpty;
  }

  /// Check if the DomainEvent is already persisted
  /// We ignore the actual payload, as soon as EventId and AggregateId match,
  /// we presume the entire DomainEvent matches.
  bool _domainEventExists(DomainEvent domainEvent) {
    return _domainEventStore[domainEvent.aggregateId].where((event) {
      return event.id == domainEvent.id && event.aggregateId == event.aggregateId;
    }).isNotEmpty;
  }

  @override
  Set<DomainEvent> getEventsForAggregate(AggregateId aggregateId) {
    return _domainEventStore[aggregateId] ?? <DomainEvent>{};
  }

  /// TODO: I want this to be a stream as this could end up being very large,
  /// but the current implementation still loads everything into a single Set...
  @override
  Set<DomainEvent> getAllDomainEvents() {
    final result = <DomainEvent>{};
    for (final aggregateId in _domainEventStore.keys) {
      result.addAll(_domainEventStore[aggregateId]);
    }
    return result;
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

/// Class that should publish events to all remote listeners
/// This way we can share locally created events with the outside world
abstract class RemoteEventPublisher {

  /// Publish a DomainEvent to the remote listener(s)
  void publishDomainEvent(DomainEvent domainEvent);

}

/// Class that should listen for events published by remote instances
abstract class RemoteEventListener {

  /// The Stream containing DomainEvents received from remote publishers
  Stream<DomainEvent> get domainEventStream;

}
