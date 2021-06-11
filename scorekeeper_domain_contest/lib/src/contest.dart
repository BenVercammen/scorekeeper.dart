
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_contest/contest.dart';


/// The (root) aggregate of our domain
/// A Contest groups together multiple Scorables, possibly in stages
@aggregate
class Contest extends Aggregate {

  late String name;

  /// The participants of the contest
  final List<Participant> participants = List.empty(growable: true);

  /// The Stage -> Scorable(Ref) map
  final Map<Stage, Set<ScorableRef>> stages = Map();

  Contest.aggregateId(AggregateId aggregateId) : super(aggregateId);

  @commandHandler
  Contest.command(CreateContest command) : super(AggregateId.of(command.aggregateId)) {
    final event = ContestCreated()
      ..contestId = ContestId(uuid: command.aggregateId)
      ..contestName = command.name;
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

  // TODO: TEST (en alle command en event handlers ook!)
  @commandHandler
  void addStage(AddStage command) {
    final stage = Stage()
      ..name = command.stageName;
    // TODO: moet in event handler, hier gewoon valideren!
    stages.putIfAbsent(stage, () => Set());
  }

  @commandHandler
  void addScorable(AddScorable command) {
    // TODO: uniek zoeken of afdwingen, niet first!?
    final stage = stages.keys.where((element) => element.name == command.stageName).first;
    // TODO: moet in event handler, hier gewoon valideren! is stage aanwezig etc...
    final scorableRef = ScorableRef()
      ..scorableId = command.scorableId;
    stages[stage]!.add(scorableRef);
  }

  // Local aggregate event handlers

  @eventHandler
  void handleContestCreated(ContestCreated event) {
    name = event.contestName;
  }

  @eventHandler
  void handleParticipantAdded(ParticipantAdded event) {
    participants.add(event.participant);
  }

  @eventHandler
  void handleParticipantRemoved(ParticipantRemoved event) {
    // TODO: evt op id ipv object... (equals moet in dit geval in Participant juist geimplementeerd zijn!)
    participants.remove(event.participant);
  }


  // Child aggregate Event Handlers

  // // TODO: zoiet in den aard?
  // @RefEventHandler(ScorableRef)
  // void handleScorableCreated(ScorableCreated event) {
  //   // TODO: dit is pas verder uit te werken zodra we aggregates gaan linken...
  //   // nu eerst voort doen met serialization!
  // }


  @override
  String toString() {
    return 'Contest $name ($aggregateId)';
  }

  CommandAllowance isAllowed(dynamic command) {
    switch (command.runtimeType) {
      default:
        return CommandAllowance(command, true, 'Allowed by default');
    }
  }

}


///////////////////////////////////////////////////////////////////////////////////////////////////////
/// COMMANDS///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

/// Command to create a new Scorable
class CreateContest {
  late String aggregateId;
  late String name;
}

/// Command to add a Participant to a Contest
/// TODO: moet ik in die commands en events ook niet meegeven voor welk type aggregate die gelden?
/// alleszins expliciet maken dat het aan een Contest toegevoegd wordt? desnoods in naamgeving?
class AddParticipant {
  late String aggregateId;
  late Participant participant;
}

class RemoveParticipant {
  late String aggregateId;
  /// Note that we use a full participant object, and not just the ID.
  /// This way we might get some extra details about the user's state
  /// at the time of removal. This could be used in the command handler to
  /// determine whether or not the participant is actually allowed to be removed.
  late Participant participant;
}

class StartContest {
  late String aggregateId;
}

class FinishContest {
  late String aggregateId;
}

class AddStage {
  late String stageName;
}

class AddScorable {
  // TODO: moet deze aggregate dan de scorable effectief instantiëren?
  // Of wordt die apart aangemaakt en hier aan toegevoegd!?
  late String stageName;
  late String scorableId;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
/// EVENTS ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

// /// Event for a newly created Contest
// class ContestCreated {
//   late String aggregateId;
//   late String name;
// }

/// Event for a newly added Participant
class ParticipantAdded {
  late String aggregateId;
  late Participant participant;
}

/// Event for a removed Participant
class ParticipantRemoved {
  late String aggregateId;
  late Participant participant;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
/// VALUE OBJECTS /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////


/// Value object used within the Contest aggregate
/// TODO: are we allowed to pass these along? We'll probably have to de-dupe this usage...
///  We now use Participant for 2 purposes:
///   - for working with inside the internal state of the aggregate
///   - for passing along in commands & events
///
/// TODO: another question, should we treat Entity/Aggregate referring VO DTO's differently?
class Participant {

  final String participantId;

  final String name;

  Participant(this.participantId, this.name);

  @override
  String toString() {
    return 'Participant $name ($participantId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant && runtimeType == other.runtimeType && participantId == other.participantId;

  @override
  int get hashCode => participantId.hashCode;
}

class ScorableRef {
  late final String scorableId;
  late final String scorableType;
}

class Stage {
  late final String name;

  late final List<Participant> participants;
}

