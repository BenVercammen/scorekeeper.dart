
import 'package:uuid/uuid.dart';

import 'aggregate.dart';

class TimestampedId {
  int sequence;
  String uuid = Uuid().v4();
  DateTime timestamp = DateTime.now();

  @override
  String toString() {
    return '$uuid@${timestamp.toIso8601String()}';
  }
}

/// ID used for a domain and integration events.
/// Is actually a composite Id in order to give the system some clues as to implement some ordering and conflict reconciliation logic.
class EventId {

  /// The ID as given by the originator
  TimestampedId _originId;

  /// The ID as given by the local event manager
  TimestampedId _localId;

  /// The ID of the previous event, to give a grip on ordering.
  // final TimestampedId prevLocalId;

  /// Constructor to be used when creating a locally generated event.
  /// The localId and originId values should be equal.
  EventId.local() {
    _originId = TimestampedId();
    _localId = _originId;
  }

  /// Constructor to be used when importing remote events
  /// The localId and originId values should be different.
  EventId.origin(EventId externalEventId) {
    _originId = externalEventId._originId;
    _localId = TimestampedId();
  }

  @override
  String toString() {
    return 'origin=$_originId, local=$_localId';
  }

  TimestampedId get originId => _originId;

  TimestampedId get localId => _localId;

}


/// ID used for system events.
class SystemEventId {

  /// The ID as given by the originator
  TimestampedId _originId;

  /// The ID as given by the local event manager
  TimestampedId _localId;

  /// Constructor to be used when creating a locally generated event.
  /// The localId and originId values should be equal.
  SystemEventId.local() {
    _originId = TimestampedId();
    _localId = _originId;
  }

  /// Constructor to be used when importing remote events
  /// The localId and originId values should be different.
  SystemEventId.origin(EventId externalEventId) {
    _originId = externalEventId._originId;
    _localId = TimestampedId();
  }

  @override
  String toString() {
    return 'origin=$_originId, local=$_localId';
  }

  TimestampedId get originId => _originId;

  TimestampedId get localId => _localId;

}


/// TODO: https://cloudevents.io/ checken
/// TODO: https://medium.com/google-cloud/using-cloud-events-and-cloud-events-generator-4b71b8a90277 checken...
/// hoe gaan we die specifiëren,
class DomainEvent<T extends Aggregate> {

  /// TODO: eventId == metadata??
  final EventId id;

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
}

/// IntegrationEvents are meant to communicate between different aggregates and/or bounded contexts.
class IntegrationEvent {
  final EventId id;

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

  final EventId notHandledEventId;

  final String reason;

  EventNotHandled(SystemEventId systemEventId, this.notHandledEventId, this.reason) : super(systemEventId);

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
