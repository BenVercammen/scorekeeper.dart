import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:uuid/uuid.dart';

/// The EventStore is responsible for persisting DomainEvents.
abstract class EventStore {

  /// Store the given DomainEvent.
  /// Returns whether or not the event was stored successfully.
  bool storeDomainEvent(DomainEvent event);

  /// Store the given SystemEvent.
  void storeSystemEvent(SystemEvent event);

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

  final String message;

  InvalidEventException(this.event, this.message);

  @override
  String toString() => message;

}

/// In memory implementation of the EventStore
///
class EventStoreInMemoryImpl implements EventStore {

  Logger _logger = Logger();

  /// Important to use a LinkedHashSet in order to preserve the insertion order!
  final Map<AggregateId, LinkedHashSet<DomainEvent>> _domainEventStore = HashMap();

  final Set<SystemEvent> _systemEventStore = <SystemEvent>{};

  final Set<AggregateId> _registeredAggregateIds = <AggregateId>{};

  EventStoreInMemoryImpl([logger]) {
    if (null != logger) {
      _logger = logger;
    }
  }

  @override
  bool storeDomainEvent(DomainEvent event) {
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
    if (_domainEventSequenceInvalid(event.aggregateId, event.sequence)) {
      throw InvalidEventException(event, 'Sequence invalid');
    }
    _domainEventStore[event.aggregateId]!.add(event);
    return true;
  }

  @override
  void storeSystemEvent(SystemEvent event) {
    _systemEventStore.add(event);
  }

  /// Check if the DomainEvent sequence is OK.
  /// Currently, this means no other event with the given sequence
  bool _domainEventSequenceInvalid(AggregateId aggregateId, int sequence) {
    // TODO: because of "memory limitations", we'll not be able to actually loop over ALL the events... probably...
    // We'll need to work with snapshots etc...
    var storedAggregateEvents = _domainEventStore[aggregateId];
    if (null == storedAggregateEvents) {
      return true;
    }
    return storedAggregateEvents.where((event) {
      return event.sequence == sequence;
    }).isNotEmpty;
  }

  /// Check if the DomainEvent is already persisted
  /// We ignore the actual payload, as soon as EventId and AggregateId match,
  /// we presume the entire DomainEvent matches.
  bool _domainEventExists(DomainEvent domainEvent) {
    var storedAggregateEvents = _domainEventStore[domainEvent.aggregateId];
    if (null == storedAggregateEvents) {
      return false;
    }
    return storedAggregateEvents.where((event) {
      return event.eventId == domainEvent.eventId && event.aggregateId == event.aggregateId;
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
      var storedAggregateEvents = _domainEventStore[aggregateId];
      result.addAll(storedAggregateEvents!);
    }
    return result;
  }

  @override
  int countEventsForAggregate(AggregateId aggregateId) {
    if (_domainEventStore.containsKey(aggregateId)) {
      return _domainEventStore[aggregateId]!.length;
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

/// Factory for creating DomainEvents.
/// Takes care of a lot of metadata prefilling.
/// TODO: This factory should probably be overidden by generated factory per domain aggregate?
/// so we can auto-fill domainId and version??
class DomainEventFactory<T extends Aggregate> {

  final String producerId;

  final String applicationVersion;

  final String domainId = 'TODO: domainId';
  final String domainVersion = 'TODO: domainVersion';

  const DomainEventFactory({
    required this.producerId,
    required this.applicationVersion,
  });

  DomainEvent<T> local(AggregateId aggregateId, int sequence, dynamic payload) {
    return _event(Uuid().v4(), DateTime.now(), aggregateId, payload, sequence);
  }

  DomainEvent<T> remote(String eventId, AggregateId aggregateId, int sequence, DateTime timestamp, payload) {
    return _event(eventId, timestamp, aggregateId, payload, sequence);
  }

  DomainEvent<T> _event(String eventId, DateTime timestamp, AggregateId aggregateId, payload, int sequence) {
    return new DomainEvent(
        eventId: eventId,
        timestamp: timestamp,

        // TODO: producerId en application version wiren??
        producerId: 'TODO: producerId',
        applicationVersion: 'TODO: applicationVersion',

        // TODO: deze wsl ook maar genereren samen met het domain...
        // dan kan ik alvast domainId en domainVersion invullen.
        domainId: domainId,
        domainVersion: domainVersion,
        aggregateId: aggregateId,
        payload: payload,
        sequence: sequence);
  }

  EventNotHandled<T> eventNotHandled(DomainEvent<T> notHandledEvent, String reason) {
    return EventNotHandled(notHandledEvent, reason, eventId: Uuid().v4(), timestamp: DateTime.now(), producerId: producerId, applicationVersion: applicationVersion, domainId: domainId, domainVersion: domainVersion);
  }

}
