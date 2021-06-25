import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';

/// This file contains classes that are purely used as an example domain.
/// In normal domains, these classes should be mostly generated.

/// The main domain aggregate
class Scorable extends Aggregate {

  late String name;

  final List<Participant> participants = List.empty(growable: true);

  Scorable.aggregateId(AggregateId scorableId) : super(scorableId);

  @commandHandler
  // TODO: ik denk dat DIT de oorzaak gaat zijn van alle problemen...
  //  We gaan hier nog iets moeten verzinnen op die AggregateId's... toch al maar meegeven ipv hier laten genereren?
  Scorable.command(CreateScorable command) : super(AggregateId.of(command.scorableId, MuurkeKlopNDown)) {
    final event = ScorableCreated()
        ..scorableId = command.scorableId
        ..name = command.name;
    apply(event);
  }

  @commandHandler
  void addParticipant(AddParticipant command) {
    final event = ParticipantAdded()
        ..scorableId = command.scorableId
        ..participantId = command.participantId;
    apply(event);
  }

  @eventHandler
  void handleScorableCreated(ScorableCreated event) {
    name = event.name;
  }

  @eventHandler
  void handleParticipantAdded(ParticipantAdded event) {
    participants.add(Participant(event.participantId, event.name));
  }

  @override
  String toString() {
    return 'Scorable $name ($aggregateId)';
  }

 CommandAllowance isAllowed(dynamic command) {
    switch (command.runtimeType) {
      default:
        return CommandAllowance(command, true, 'Allowed by default');
    }
  }

}

/// Command to create a new Scorable
class CreateScorable {
  late String scorableId;
  late String name;
}

/// Event for a newly created Scorable
class ScorableCreated {
  late String scorableId;
  late String name;
}

/// Command to add a new Participant
class AddParticipant {
  late String scorableId;
  late String participantId;
  late String name;
}

/// Event for a newly added Participant
class ParticipantAdded {
  late String scorableId;
  late String participantId;
  late String name;
}

/// Value object
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