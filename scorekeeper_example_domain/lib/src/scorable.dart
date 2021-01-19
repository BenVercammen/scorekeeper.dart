
import 'package:scorekeeper_domain/core.dart';

/// The (root) aggregate of our domain
@aggregate
class Scorable extends Aggregate {

  String name;

  final List<Participant> participants = List.empty(growable: true);

  Scorable.aggregateId(AggregateId aggregateId) : super(aggregateId);

  @commandHandler
  Scorable.command(CreateScorable command) : super(AggregateId.of(command.aggregateId)) {
    if (null == command.name) {
      throw Exception('Invalid name');
    }
    final event = ScorableCreated()
      ..aggregateId = command.aggregateId
      ..name = command.name;
    apply(event);
  }

  @commandHandler
  void addParticipant(AddParticipant command) {
    final participant = command.participant;
    if (participants.contains(participant)) {
      throw Exception('Participant already added to Scorable');
    }
    final event = ParticipantAdded()
      ..aggregateId = command.aggregateId
      ..participant = command.participant;
    apply(event);
  }

  @commandHandler
  void removeParticipant(RemoveParticipant command) {
    final participant = command.participant;
    if (!participants.contains(participant)) {
      throw Exception('Participant not on Scorable');
    }
    final event = ParticipantRemoved()
      ..aggregateId = command.aggregateId
      ..participant = command.participant;
    apply(event);
  }

  @eventHandler
  void handleScorableCreated(ScorableCreated event) {
    name = event.name;
  }

  @eventHandler
  void handleParticipantAdded(ParticipantAdded event) {
    participants.add(event.participant);
  }

  @eventHandler
  void handleParticipantRemoved(ParticipantRemoved event) {
    // TODO: evt op id ipv object... (equals)
    participants.remove(event.participant);
  }

  @override
  String toString() {
    return 'Scorable $name ($aggregateId)';
  }

}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// TODO: the classes below are events, commands and value objects that are to be generated with protobuf.
/// however, this also means they cannot implement anything...
/// we either have to create "wrapper classes" in our application (meh)
/// or use reflection...
/// hmm, het reflection path geeft in flutter al problemen...
/// de wrapper classes zijn extra werk, maar dan is het wel "type safe"
///
/// Probleem hiermee is da'k dan in de handlers nog steeds die extended commands moet gebruiken als arguments
/// dus type-gewijs ben ik er nog altijd niet veel mee... :/
///
/// Ik wil niet dat ik in de aggregate zelf met gegenereerde/wrapper classes moet werken......
/// pff, ik wil toch reflection blijven gebruiken :/
/// tenzij die aggregates én die commands én events dus allemaal door een "compilatie" fase moeten gaan...
///   -> ik schrijf een domain lib, heel droog en sec, met de nodige protobufs voor events, commands, value-objects, ...
///   -> die lib moet dan "samen met de applicatie" "gecompileerd" worden?
///     - dependency binnen trekken
///     - gradle build scriptje om domain classes te enrichen
///     - klaar?
///     - wel voos, dien extra stap ertussen...
///     -> zou eigenlijk het domain package moeten builden zodanig dat de generated code enriched wordt?
///
/// https://medium.com/flutter-community/part-1-code-generation-in-dart-the-basics-3127f4c842cc
///   source_gen + build_runner


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// Command to create a new Scorable
class CreateScorable {

  String aggregateId;

  String name;

}

/// Command to add a Participant to a Scorable
class AddParticipant {

  /// TODO: moet ik in die commands en events ook niet meegeven voor welk type aggregate die gelden?
  /// alleszins expliciet maken dat het aan een Scorable toegevoegd wordt? desnoods in naamgeving?

  String aggregateId;

  Participant participant;

}

class RemoveParticipant {

  String aggregateId;

  /// Note that we use a full participant object, and not just the ID.
  /// This way we might get some extra details about the user's state
  /// at the time of removal. This could be used in the command handler to
  /// determine whether or not the participant is actually allowed to be removed.
  Participant participant;

}

/// Event for a newly created Scorable
class ScorableCreated {

  String aggregateId;

  String name;

}

/// Event for a newly added Participant
class ParticipantAdded {

  String aggregateId;

  Participant participant;

}

/// Event for a removed Participant
class ParticipantRemoved {

  String aggregateId;

  Participant participant;

}

/// Value object used within the Scorable aggregate
class Participant {

  String participantId;

  String name;

}

