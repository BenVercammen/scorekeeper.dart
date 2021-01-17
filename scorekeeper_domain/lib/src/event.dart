
import 'package:uuid/uuid.dart';

import 'aggregate.dart';

/// A composite ID that contains sequence, UUID and timestamp values.
class DomainEventId {

  String _uuid;

  final int _sequence;

  DateTime _timestamp;

  /// Constructor to be used when creating a locally generated event.
  /// The local and origin values should be equal.
  DomainEventId.local(this._sequence) {
    _uuid = Uuid().v4();
    _timestamp = DateTime.now();
  }

  String get uuid => _uuid;

  int get sequence => _sequence;

  DateTime get timestamp => _timestamp;

  @override
  String toString() {
    return '$_sequence@$_uuid@${_timestamp.toIso8601String()}';
  }

}


/// ID used for system events.
class SystemEventId {

  String _uuid;

  DateTime _timestamp;

  /// Constructor to be used when creating a locally generated event.
  /// The localId and originId values should be equal.
  SystemEventId.local() {
    _uuid = Uuid().v4();
    _timestamp = DateTime.now();
  }

  String get uuid => _uuid;

  DateTime get timestamp => _timestamp;

  @override
  String toString() {
    return '$_uuid@${_timestamp.toIso8601String()}';
  }

}


/// TODO: https://cloudevents.io/ checken
/// TODO: https://medium.com/google-cloud/using-cloud-events-and-cloud-events-generator-4b71b8a90277 checken...
/// hoe gaan we die specifiëren?
/// DomainEvent = payload + metadata, en enkel die payload is voor onze aggregate interessant...
class DomainEvent<T extends Aggregate> {

  final DomainEventId id;

  final AggregateId aggregateId;

  final dynamic payload;

  DomainEvent.of(this.id, this.aggregateId, this.payload);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DomainEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // TODO: deze had ik liever niet in DomainEvent gestoken, maar ergens maakt het wel sense dat we weten welke aggregate dit event emit...
  Type get aggregateType => T;

  @override
  String toString() {
    return 'Event $id for aggregate $aggregateId with payload type ${payload.runtimeType}';
  }
}

/// IntegrationEvents are meant to communicate between different aggregates and/or bounded contexts.
class IntegrationEvent {
  final SystemEventId id;

  IntegrationEvent(this.id);
}

/// SystemEvents represent events that are not directly related to any given Domain.
/// They can be used to
///   - communicate exceptions during event handling
///   - general system events, like components shutting down, time points passed, ...
///
abstract class SystemEvent {
  final SystemEventId id;

  SystemEvent(this.id);
}

/// SystemEvent that tells the system that a given event was not handled for some reason
class EventNotHandled extends SystemEvent {

  final DomainEventId notHandledEventId;

  final String reason;

  EventNotHandled(this.notHandledEventId, this.reason) : super(SystemEventId.local());

  @override
  String toString() {
    return "Event $notHandledEventId couldn't be handled because $reason";
  }

}







/// TODO: is nog "toekomstmuziek"... mogelijks DomainEvent hier al zo hard mogelijk op enten?
abstract class CloudEvent {

  String specversion;

  String type;

  String source;

  String subject;

  String id;

  DateTime time;

  String datacontenttype;


  /// This one is the actual payload...
  /// moet ik per se protobuf gebruiken?
  /// TODO: POC: protobuf value omzetten naar non-generated class??
  Object data;

}
