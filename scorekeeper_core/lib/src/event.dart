import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:ordered_set/ordered_set.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:uuid/uuid.dart';

/// The EventStore is responsible for persisting DomainEvents.
abstract class EventStore {

  /// Store the given DomainEvent or throw an exception
  void storeDomainEvent(DomainEvent event);

  /// Store the given SystemEvent.
  void storeSystemEvent(SystemEvent event);

  /// Get the number of events for a single aggregate
  int countEventsForAggregate(AggregateId aggregateId);

  /// Get all domain events by the given criteria
  OrderedSet<DomainEvent> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp});

  /// Get all system events
  Set<SystemEvent> getSystemEvents();

  void registerAggregateId(AggregateId aggregateId);

  void registerAggregateIds(Iterable<AggregateId> aggregateIds);

  void unregisterAggregateId(AggregateId aggregateId);

  bool hasEventsForAggregate(AggregateId aggregateId);

  _validateDomainEvent(DomainEvent event) {
    if (event.sequence < 0) {
      throw new InvalidEventException(event, "Invalid sequence");
    }
  }

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
  }

  @override
  void storeDomainEvent(DomainEvent event) {
    // If the aggregateId is not yet registered, throw an exception
    // (yes, Aggregates need to be registered explicitly)
    if (!_registeredAggregateIds.contains(event.aggregateId)) {
      throw new InvalidEventException(event, 'AggregateId not registered');
    }
    _validateDomainEvent(event);
    _domainEventStore.putIfAbsent(event.aggregateId, () => LinkedHashSet<DomainEvent>());
    // In case of duplicate event, ignore siltently
    if (_domainEventExists(event)) {
      _logger.i('Received and ignored duplicate $event');
      return;
    }
    // EventId should be unique
    _checkUniqueEventId(event);
    // Also check if the sequence is unique
    if (_domainEventSequenceInvalid(event.aggregateId, event.sequence)) {
      throw InvalidEventException(event, 'Sequence invalid');
    }
    _domainEventStore[event.aggregateId]!.add(event);
  }

  @override
  void storeSystemEvent(SystemEvent event) {
    _systemEventStore.add(event);
  }

  /// Make sure that there is only one event with the given EventId
  /// TODO: hmm, this is quite a heavy operation... digging through all aggregates and their events...
  void _checkUniqueEventId(DomainEvent event) {
    _domainEventStore.values.forEach((aggregateEvents) {
      if (aggregateEvents.where((aggregateEvent) => aggregateEvent.eventId == event.eventId).isNotEmpty) {
        throw new InvalidEventException(event, 'Non-identical event with the same ID already stored in EventStore');
      }
    });
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
  /// We ignore the actual payload, as soon as EventId, AggregateId and sequence match,
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

  /// TODO: I want this to be a stream as this could end up being very large,
  /// but the current implementation still loads everything into a single Set...
  @override
  OrderedSet<DomainEvent> getDomainEvents({AggregateId? aggregateId, DateTime? timestamp}) {
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
    return OrderedSet<DomainEvent>((DomainEvent dto1, DomainEvent dto2) {
      return dto1.sequence - dto2.sequence;
    })..addAll(result);
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
