import 'package:uuid/uuid.dart';

/// Parent class for all Aggregates.
/// Adds the AggregateId to an Aggregate, as well as the capability to send out events.
abstract class Aggregate {

  final AggregateId _aggregateId;

  AggregateId get aggregateId => _aggregateId;

  /// The time at which the last event was applied.
  /// TODO: this does NOT correspond to the actual DomainEvent's timestamp! is that okay?
  DateTime _lastModified;

  DateTime get lastModified => _lastModified;

  /// We always require an aggregateId
  Aggregate(this._aggregateId);

  /// All domain events that the aggregate applied on itself.
  /// the command handler should take "freshly applied" events off this Set after each (succesful?) handle
  Set<dynamic> appliedEvents = <dynamic>{};

  /// Adds a locally created Domain Event to this Aggregate.
  /// The Scorekeeper instance will pick this up while handling the command.
  /// The event will then be handled through the EventHandler wired into the Scorekeeper instance.
  /// Finally, the event will be stored in the LocalEventManager and possibly published to the RemoteEventManager.
  /// Please note that anything can be used as an eventPayload, as this method will wrap it into a DomainEvent for us.
  void apply(dynamic event) {
    appliedEvents.add(event);
    _lastModified = DateTime.now();
  }

}


/// The Aggregate as a value-object, stripped of all its handler methods.
/// This one can be passed along to clients without worrying that they'll call any handlers.
///
/// TODO: probleem is wel dat het nu niet duidelijk is wie dien DTO up-to-date gaat houden...
/// Op zich, telkens een aggregate opgevraagd wordt, moet daar een DTO copy van gemaakt worden...
/// In Axon doet de ViewProjector dat, die gaat een "JPA Repository" aansturen om @Entity te manipuleren en op te slaan
/// Da's dan in het query model...
/// Wij willen echter command/query model (voorlopig) nog gelijk houden... al kunnen andere implementaties daar mss nog wel anders op inspelen
/// Soit, een soort projector genereren die dezelfde event handlers uit de Aggregate kopieert?
///   -> alle "locally applied events" moeten dus zowel naar Aggregate handlers als naar Projection handlers gestuurd worden
///   -> alle "remotely received events" moeten eveneens naar beide handlers gestuurd worden...
/// Eigenlijk ben ik nu een manier aan't vinden om automatisch een 1-op-1 command/query model projector / event handler  te bouwen
///
/// OKE, WAAROM bother ik nog met die COMMANDS???
///  - op zich ga ik toch gewoon lokaal rechtstreeks de nodige methodes uitvoeren en state updaten
///  - ik kan in principe gewoon "doXxx" uitvoeren en de resulterende events opvragen en uitsturen...
///   -> voordeel van event handlers te hebben, is dat die op 2 manieren getriggerd kunnen worden, dus geen duplicate code!
///   -> de "doXxx" methodes gaan gewoon invariants afchecken en event(s) apply'en die opgeslagen worden voor later reference
///   -> maar daar hebben we nog wel steeds niet per se commands voor nodig...
///   -> voordeel van commands is dat ... den aggregate duidelijk opgesplitst wordt?
///
///
abstract class AggregateDto<T extends Aggregate> {

  final T _aggregate;

  AggregateDto(this._aggregate);

  AggregateId get aggregateId => _aggregate.aggregateId;

  DateTime get lastModified => _aggregate.lastModified;

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
