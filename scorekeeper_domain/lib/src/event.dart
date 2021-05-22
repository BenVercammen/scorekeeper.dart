

import 'aggregate.dart';

// This is where we define the events we use.
// For now we don't do "Cloud Events", we consider them to be some sort of "wrapper"
// in case we send out data to external consumers.
// We do however try to collect all required data so we can easily support this later on.
// See https://github.com/cloudevents/spec/blob/master/spec.md


/// The metadata for an event.
///  - uuid: the actual event ID
///  - sequence: the sequence
abstract class Event {

  /// The actual UUID of the event
  final String _eventId;

  /// The timestamp the event was created
  final DateTime _timestamp;

  /// The ID of the user that triggered the event
  final String? _userId;

  /// The ID of the process that triggered the event
  final String? _processId;

  /// The ID of the producer of the event.
  /// This can be either the ID of the client's machine,
  /// or some sort of automated process (for external events).
  final String _producerId;

  /// The version of the scorekeeper application used by the producer of the event.
  final String _applicationVersion;

  /// The ID of the domain
  final String _domainId;

  /// The version of the domain
  final String _domainVersion;

  /// The actual payload of the event, contains all relevant domain data
  final dynamic _payload;

  const Event({
    required String eventId,
    required DateTime timestamp,
    String? userId,
    String? processId,
    required String producerId,
    required String applicationVersion,
    required String domainId,
    required String domainVersion,
    required dynamic payload,
  })  : _eventId = eventId,
        _timestamp = timestamp,
        _userId = userId,
        _processId = processId,
        _producerId = producerId,
        _applicationVersion = applicationVersion,
        _domainId = domainId,
        _domainVersion = domainVersion,
        _payload = payload;

  String get eventId => _eventId;

  DateTime get timestamp => _timestamp;

  String? get userId => _userId;

  String? get processId => _processId;

  String get producerId => _producerId;

  String get applicationVersion => _applicationVersion;

  String get domainId => _domainId;

  String get domainVersion => _domainVersion;

  dynamic get payload => _payload;

  @override
  String toString() {
    return '$_eventId@${_timestamp.toIso8601String()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          _eventId == other._eventId &&
          _timestamp == other._timestamp &&
          _userId == other._userId &&
          _processId == other._processId &&
          _producerId == other._producerId &&
          _applicationVersion == other._applicationVersion &&
          _domainId == other._domainId &&
          _domainVersion == other._domainVersion;

  @override
  int get hashCode =>
      _eventId.hashCode ^
      _timestamp.hashCode ^
      _userId.hashCode ^
      _processId.hashCode ^
      _producerId.hashCode ^
      _applicationVersion.hashCode ^
      _domainId.hashCode ^
      _domainVersion.hashCode;
}


/// TODO: https://cloudevents.io/ checken
/// TODO: https://medium.com/google-cloud/using-cloud-events-and-cloud-events-generator-4b71b8a90277 checken...
/// hoe gaan we die specifiëren?
/// DomainEvent = payload + metadata, en enkel die payload is voor onze aggregate interessant...
class DomainEvent<T extends Aggregate> extends Event {

  /// The sequence of the event
  final int _sequence;

  /// The ID of the aggregate of the event
  final AggregateId _aggregateId;

  const DomainEvent({
    required String eventId,
    required DateTime timestamp,
    String? userId,
    String? processId,
    required String producerId,
    required String applicationVersion,
    required String domainId,
    required String domainVersion,
    required dynamic payload,
    required AggregateId aggregateId,
    required int sequence,
  })   : _sequence = sequence,
        _aggregateId = aggregateId,
        super(
            eventId: eventId,
            timestamp: timestamp,
            userId: userId,
            processId: processId,
            producerId: producerId,
            applicationVersion: applicationVersion,
            domainId: domainId,
            domainVersion: domainVersion,
            payload: payload);

  AggregateId get aggregateId => _aggregateId;

  int get sequence => _sequence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      // super == other &&
          other is DomainEvent &&
          eventId == other.eventId &&
          runtimeType == other.runtimeType &&
          sequence == other.sequence &&
          aggregateId == other.aggregateId &&
          // TODO: mja.... ik wil hier niet op instance checken, maar op inhoud...
          payload == other.payload;

  @override
  int get hashCode =>
      eventId.hashCode ^
      sequence.hashCode ^
      aggregateId.hashCode ^
      payload.hashCode;

  // TODO: deze had ik liever niet in DomainEvent gestoken, maar ergens maakt het wel sense dat we weten door welk type aggregate dit event ge-emit werd...
  Type get aggregateType => T;

  @override
  String toString() {
    return 'Event $_eventId ($_sequence) for aggregate $_aggregateId with payload type ${_payload.runtimeType} ($timestamp)';
  }

}
//
// /// IntegrationEvents are meant to communicate between different aggregates and/or bounded contexts.
// class IntegrationEvent {
//   final SystemEventId id;
//
//   IntegrationEvent(this.id);
// }

/// SystemEvents represent events that are not directly related to any given Domain.
/// They can be used to
///   - communicate exceptions during event handling
///   - general system events, like components shutting down, time points passed, ...
///
abstract class SystemEvent extends Event {

  const SystemEvent({
    required String eventId,
    required DateTime timestamp,
    String? userId,
    String? processId,
    required String producerId,
    required String applicationVersion,
    required String domainId,
    required String domainVersion,
    required dynamic payload,
  })   : super(
      eventId: eventId,
      timestamp: timestamp,
      userId: userId,
      processId: processId,
      producerId: producerId,
      applicationVersion: applicationVersion,
      domainId: domainId,
      domainVersion: domainVersion,
      payload: payload);

  /// Constructor to be used when creating a locally generated event.
  /// The localId and originId values should be equal.
  // SystemEventId.local() {
  //   _uuid = const Uuid().v4();
  //   _timestamp = DateTime.now();
  // }
  @override
  String toString() {
    return '$eventId@${_timestamp.toIso8601String()}';
  }
}

/// SystemEvent that tells the system that a given event was not handled for some reason
class EventNotHandled<T extends Aggregate> extends SystemEvent {

  final String reason;

  const EventNotHandled(notHandledEvent, this.reason, {
    required String eventId,
    required DateTime timestamp,
    String? userId,
    String? processId,
    required String producerId,
    required String applicationVersion,
    required String domainId,
    required String domainVersion,
  })   : super(
      eventId: eventId,
      timestamp: timestamp,
      userId: userId,
      processId: processId,
      producerId: producerId,
      applicationVersion: applicationVersion,
      domainId: domainId,
      domainVersion: domainVersion,
      payload: notHandledEvent);

  dynamic get notHandledEvent => _payload;

  @override
  String toString() {
    return "Event $_payload.id couldn't be handled because $reason";
  }

}
