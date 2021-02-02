
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

/// Aggregate specifically for the Muurke Klop N-down type game
@aggregate
class MuurkeKlopNDown extends Scorable {

  final Map<int, MuurkeKlopNDownRound> rounds = Map();

  MuurkeKlopNDown.aggregateId(AggregateId aggregateId) : super.aggregateId(aggregateId);

  @commandHandler
  MuurkeKlopNDown.command(CreateScorable command) : super.command(command);

  @commandHandler
  void addRound(AddRound command) {
    final event = RoundAdded()
      ..aggregateId = command.aggregateId
      ..roundIndex = rounds.length;
    apply(event);
  }

  @commandHandler
  void removeRound(RemoveRound command) {
    final event = RoundRemoved()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void strikeOutParticipant(StrikeOutParticipant command) {
    // TODO: check if roundindex is correct, or ...
    // TODO: deze contains (equals) is ook maar geldig zolang participant hetzelfde blijft he
    //  tenzij we de equals enkel op participantId zetten... wat voor value objects niet oké is...
    //  dus: test voor schrijven en fixen!
    if (rounds[command.roundIndex].strikeOutOrder.containsValue(command.participant)) {
      throw Exception('${command.participant.name} already striked out in round ${command.roundIndex + 1}');
    }
    final event = ParticipantStrikedOut()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex
      ..participant = command.participant;
    apply(event);
  }

  @commandHandler
  void undoParticipantStrikeout(UndoParticipantStrikeOut command) {
    // TODO: validate command!
    final event = ParticipantStrikeOutUndone()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex
      ..participant = command.participant;
    apply(event);
  }

  @eventHandler
  void roundAdded(RoundAdded event) {
    final round = MuurkeKlopNDownRound(event.roundIndex);
    rounds.putIfAbsent(round.roundIndex, () => round);
  }

  @eventHandler
  void roundRemoved(RoundRemoved event) {
    rounds.remove(event.roundIndex);
  }

  @eventHandler
  void participantStrikedOut(ParticipantStrikedOut event) {
    final round = rounds[event.roundIndex];
    round.strikeOutParticipant(event.participant);
  }

  @eventHandler
  void participantStrikeOutUndone(ParticipantStrikeOutUndone event) {
    final round = rounds[event.roundIndex];
    round.undoStrikeOutParticipant(event.participant);
  }

}



///////////////////////////////////////////////////////////////////////////////////////////////////////
/// COMMANDS///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

/// When a participant strikes out, he/she will receive a fixed number of points depending
/// on the order in which he was striked out.
class StrikeOutParticipant {
  String aggregateId;
  Participant participant;
  int roundIndex;
}

class UndoParticipantStrikeOut {
  String aggregateId;
  Participant participant;
  int roundIndex;
}

/// Add an extra Round to the Scorable
class AddRound {
  String aggregateId;
}

/// Remove an existing Round from the Scorable
class RemoveRound {
  String aggregateId;
  int roundIndex;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
/// EVENTS ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

class ParticipantStrikedOut {
  String aggregateId;
  Participant participant;
  int roundIndex;
}

class ParticipantStrikeOutUndone {
  String aggregateId;
  Participant participant;
  int roundIndex;
}

class RoundAdded {
  String aggregateId;
  int roundIndex;
}

class RoundRemoved {
  String aggregateId;
  int roundIndex;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
/// VALUE OBJECTS /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////


/// Round as used within the Scorable
/// TODO: for now not part of the base Scorable class, as not all scorables consist of rounds
///   maybe we can add a "ScorableWithRounds" mixin or something?
class Round {
  final int roundIndex;

  Round(this.roundIndex);

}

/// Round as used within the MuurkeKlopNDown scorable
class MuurkeKlopNDownRound extends Round {
  final Map<int, Participant> strikeOutOrder = Map();

  MuurkeKlopNDownRound(int roundIndex) : super(roundIndex);

  void strikeOutParticipant(Participant participant) {
    strikeOutOrder[strikeOutOrder.length] = participant;
  }

  void undoStrikeOutParticipant(Participant participant) {
    strikeOutOrder.removeWhere((strikeOutIndex, strikedOutParticipant) => strikedOutParticipant == participant);
  }
}