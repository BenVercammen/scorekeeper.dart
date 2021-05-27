import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:ordered_set/ordered_set.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:uuid/uuid.dart';

/// The EventStore is responsible for persisting DomainEvents of a single instance.
/// The EventStore will only accept events when
///  - the aggregateId is registered up front (else ignore)
///  - the event sequence is correct (ignore if duplicate event, throw exception otherwise)
///
/// Question: should we have 2 event stores to keep track of events for an aggregate
///   -> local events
///   -> remote events
///   Or do we want to make our EventStore intelligent enough to resolve conflicts between sources???
///
abstract class EventStore {

  /// Store the given DomainEvent or throw an exception
  Future<void> storeDomainEvent(DomainEvent event);

  /// Store the given SystemEvent.
  Future<void> storeSystemEvent(SystemEvent event);

  /// Get the number of events for a single aggregate
  Future<int> countEventsForAggregate(AggregateId aggregateId);

  /// Get all domain events by the given criteria
  Stream<DomainEvent> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp});

  /// Get all domain events that have been "quarantined" because they conflict with the remote event store
  /// TODO: do we really want to go there?
  /// TODO Stream<DomainEvent> getConflictingDomainEvents(AggregateId aggregateId);

  /// Get all system events
  Stream<SystemEvent> getSystemEvents();

  Future<void> registerAggregateId(AggregateId aggregateId);

  Future<void> registerAggregateIds(Iterable<AggregateId> aggregateIds);

  Future<void> unregisterAggregateId(AggregateId aggregateId);

  Future<bool> hasEventsForAggregate(AggregateId aggregateId);

  Future<void> validateDomainEvent(DomainEvent event);

  Future<int> nextSequenceForAggregate(AggregateId aggregateId);

  /// Remove all events from the EventStore
  Future<void> clear();

  Future<bool> isRegisteredAggregateId(AggregateId aggregateId);

  Stream<AggregateId> registeredAggregateIds();

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
/// Should only be used in tests...
///
class EventStoreInMemoryImpl extends EventStore {

  Logger _logger = Logger();

  /// Important to use a LinkedHashSet in order to preserve the insertion order!
  final Map<AggregateId, LinkedHashSet<DomainEvent>> _domainEventStore = HashMap();

  final Set<SystemEvent> _systemEventStore = <SystemEvent>{};

  final Set<AggregateId> _registeredAggregateIds = <AggregateId>{};

  EventStoreInMemoryImpl([logger]) {
    if (null != logger) {
      _logger = logger;
    }
    // TODO: only log in non-testing environment?!
    // _logger.w('Please note that the in memory implementation should only be used in tests, or with a small amount of events');
  }

  @override
  Future<void> storeDomainEvent(DomainEvent event) async {
    await validateDomainEvent(event);
    // Finally, persist!
    _domainEventStore.putIfAbsent(event.aggregateId, () => LinkedHashSet<DomainEvent>());
    _domainEventStore[event.aggregateId]!.add(event);
  }

  Future<void> validateDomainEvent(DomainEvent event) async {
    if (event.sequence < 0) {
      throw new InvalidEventException(event, "Invalid sequence");
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

  /// Make sure that there is only one event in the entiry event store with the given EventId
  /// TODO: hmm, this is quite a heavy operation... digging through all aggregates and their events...
  Future<void> _checkUniqueEventId(DomainEvent event) async {
    await getDomainEvents().forEach((aggregateEvent) {
      if (aggregateEvent.eventId == event.eventId) {
        throw new InvalidEventException(event, 'Non-identical event with the same ID already stored in EventStore');
      }
    });
  }

  /// Check if the DomainEvent sequence is OK.
  /// Currently, this means no other event with the given sequence
  Future<void> _domainEventSequenceInvalid(DomainEvent event) async {
    final nextSequence = await nextSequenceForAggregate(event.aggregateId);
    _logger.w('next sequence for aggregate ${event.aggregateId.id}: $nextSequence - current sequence == ${event.sequence}');
    if (nextSequence != event.sequence) {
      throw InvalidEventException(event, 'Sequence invalid: expected ${nextSequence} but was ${event.sequence}');
    }
  }

  /// Check if the DomainEvent is already persisted
  /// We ignore the actual payload, as soon as EventId, AggregateId and sequence match,
  /// we presume the entire DomainEvent matches.
  Future<void> _checkDomainEventExists(DomainEvent domainEvent) async {
    final storedAggregateEvents = getDomainEvents(aggregateId: domainEvent.aggregateId);
    final matches = await storedAggregateEvents.where((event) {
      return event.eventId == domainEvent.eventId && event.aggregateId == event.aggregateId;
    }).toList();
    if (!matches.isEmpty) {
      throw new InvalidEventException(domainEvent, 'Event already stored');
    }
  }

  @override
  Future<void> storeSystemEvent(SystemEvent event) async {
    return Future.sync(() => _systemEventStore.add(event));
  }

  /// TODO: I want this to be a stream as this could end up being very large,
  /// but the current implementation still loads everything into a single Set...
  @override
  Stream<DomainEvent> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp}) {
    var result = <DomainEvent>{};
    if (aggregateId != null) {
      result.addAll(_domainEventStore[aggregateId] ?? <DomainEvent>{});
    } else {
      for (final aggregateId in _domainEventStore.keys) {
        var storedAggregateEvents = _domainEventStore[aggregateId];
        result.addAll(storedAggregateEvents!);
      }
    }
    if (timestamp != null) {
      result = <DomainEvent>{}..addAll(result.where((event) => !event.timestamp.isBefore(timestamp)));
    }
    return Stream.fromIterable(OrderedSet<DomainEvent>((DomainEvent dto1, DomainEvent dto2) {
      return dto1.sequence - dto2.sequence;
    })..addAll(result));
  }

  @override
  Future<int> countEventsForAggregate(AggregateId aggregateId) async {
    if (_domainEventStore.containsKey(aggregateId)) {
      return _domainEventStore[aggregateId]!.length;
    }
    return 0;
  }

  @override
  Stream<SystemEvent> getSystemEvents() {
    return Stream.fromIterable(_systemEventStore);
  }

  @override
  Future<void> registerAggregateId(AggregateId aggregateId) async {
    _registeredAggregateIds.add(aggregateId);
  }

  @override
  Future<void> registerAggregateIds(Iterable<AggregateId> aggregateIds) async {
    _registeredAggregateIds.addAll(aggregateIds);
  }

  @override
  Future<void> unregisterAggregateId(AggregateId aggregateId) async {
    _registeredAggregateIds.remove(aggregateId);
    _domainEventStore.removeWhere((key, value) => key == aggregateId);
  }

  @override
  Future<bool> hasEventsForAggregate(AggregateId aggregateId) async {
    return Future.sync(() => _domainEventStore.containsKey(aggregateId));
  }

  @override
  Future<void> clear() async {
    _domainEventStore.clear();
  }

  @override
  Future<bool> isRegisteredAggregateId(AggregateId aggregateId) {
    return Future.sync(() => _registeredAggregateIds.contains(aggregateId));
  }

  @override
  Future<int> nextSequenceForAggregate(AggregateId aggregateId) {
    return Future.sync(() => _domainEventStore.containsKey(aggregateId)
        ? _domainEventStore[aggregateId]!.length
        : 0);
  }

  @override
  Stream<AggregateId> registeredAggregateIds() {
    return Stream.fromIterable(_registeredAggregateIds);
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

  // TODO: https://stackoverflow.com/questions/23613279/access-to-pubspec-yaml-attributes-version-from-dart-app
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
