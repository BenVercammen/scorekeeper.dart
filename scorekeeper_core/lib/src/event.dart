import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_domain/core.dart';

/// The EventManager is responsible for persisting and publishing DomainEvents.
/// It receives events from the local domain and
///
///  - persist all events that were published by the Scorekeeper instance
///  - persist all events coming in from another EventManager
///  - publish all events to another EventManager
///  - ...
///
abstract class EventManager {

  /// Store the given DomainEvent
  /// Command handlers already apply the event themselves and thus shoud not publish them again.
  /// Returns whether or not the event was stored successfully.
  /// This is very important, as non-persisted events should never be published
  bool store(DomainEvent event);

  /// Store and publish the given DomainEvent.
  /// Publishing means emitting it through the [#eventStream] method
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

  /// Get all domain events that are stored within
  Set<DomainEvent> getAllDomainEvents();

}

/// In memory implementation of the EventManager
///
class EventManagerInMemoryImpl implements EventManager {

  Logger _logger;

  /// Important to use a LinkedHashSet in order to preserve the insertion order!
  final Map<AggregateId, LinkedHashSet<DomainEvent>> _domainEventStore = HashMap();

  final Set<SystemEvent> _systemEventStore = <SystemEvent>{};

  final StreamController<DomainEvent> _domainEventController = StreamController<DomainEvent>();

  final StreamController<SystemEvent> _systemEventController = StreamController<SystemEvent>();

  final Set<AggregateId> _registeredAggregateIds = <AggregateId>{};

  EventManagerInMemoryImpl([this._logger]) {
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
      /// We'll store the event for now, but we'll also emit a SystemEvent so the error can be handled accordingly...
      _domainEventStore[event.aggregateId].add(event);
      final systemEvent = EventNotHandled(event.id, 'Sequence invalid');
      _systemEventStore.add(systemEvent);
      _systemEventController.add(systemEvent);
      _logger.i('Received event with invalid sequence $event');
      return false;
    } else {
      _domainEventStore[event.aggregateId].add(event);
      return true;
    }
  }

  @override
  void storeAndPublish(DomainEvent event) {
    // Ignore this event. We only store events for the registered aggregates, the others will need to be pulled from the remote event manager
    if (!_registeredAggregateIds.contains(event.aggregateId)) {
      return;
    }
    if (!store(event)) {
      _logger.w('Could not publish $event because it was not stored properly');
    }
    _domainEventController.add(event);
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
  Stream<DomainEvent> get domainEventStream => _domainEventController.stream.asBroadcastStream();

  @override
  Stream<SystemEvent> get systemEventStream => _systemEventController.stream.asBroadcastStream();

  @override
  Set<DomainEvent> getEventsForAggregate(AggregateId aggregateId) {
    return _domainEventStore[aggregateId] ?? <DomainEvent>{};
  }

  /// TODO: I want this to be a stream as this could end up being very large,
  /// but the current implementation still loads everything into a single Set...
  @override
  Set<DomainEvent> getAllDomainEvents() {
    final result = <DomainEvent>{};
    for (AggregateId aggregateId in _domainEventStore.keys) {
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
