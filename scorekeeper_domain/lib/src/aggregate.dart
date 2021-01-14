import 'package:uuid/uuid.dart';

/// Parent class for all Aggregates.
/// Adds the AggregateId to an Aggregate, as well as the capability to send out events.
abstract class Aggregate {

  final AggregateId _aggregateId;

  AggregateId get aggregateId => _aggregateId;

  /// We always require an aggregateId
  Aggregate(AggregateId this._aggregateId);

  /// All domain events that the aggregate applied on itself.
  /// the command handler should take "freshly applied" events off this Set after each (succesful?) handle
  /// TODO: test! (en zijn we zeker dat dat oké is?)
  Set<dynamic> appliedEvents = <dynamic>{};

  /// Adds a locally created Domain Event to this Aggregate.
  /// The Scorekeeper instance will pick this up while handling the command.
  /// The event will then be handled through the EventHandler wired into the Scorekeeper instance.
  /// Finally, the event will be stored in the LocalEventManager and possibly published to the RemoteEventManager.
  /// Please note that anything can be used as an eventPayload, as this method will wrap it into a DomainEvent for us.
  void apply(dynamic event) {
    appliedEvents.add(event);
  }

}


/// The ID of an aggregate.
class AggregateId {
  final String id;

  AggregateId._(this.id);

  static AggregateId of(String id) {
    return AggregateId._(id);
  }

  static AggregateId random() {
    return AggregateId._(Uuid().v4());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AggregateId && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'aggregateId=$id';
  }
}


/// Annotation to mark a given aggregate method as an Aggregate
class AggregateAnnotation {
  const AggregateAnnotation();
}
const aggregate = AggregateAnnotation();

/// Annotation to mark a given aggregate method as command handler
class CommandHandlerAnnotation {
  const CommandHandlerAnnotation();
}
const commandHandler = CommandHandlerAnnotation();

/// Annotation to mark a given aggregate method as event handler
class EventHandlerAnnotation {
  const EventHandlerAnnotation();
}

/// Mark the method as an event handler. Method should take exactly one argument.
const eventHandler = EventHandlerAnnotation();
