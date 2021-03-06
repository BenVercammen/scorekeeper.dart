
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

/// Aggregate specifically for the Muurke Klop N-down type game
@aggregate
class MuurkeKlopNDown extends Scorable {

  final Map<int, MuurkeKlopNDownRound> rounds = Map();

  MuurkeKlopNDown.aggregateId(AggregateId aggregateId) : super.aggregateId(aggregateId);

  @commandHandler
  MuurkeKlopNDown.command(CreateScorable command) : super.command(command) {
    // TODO: By default a Muurke Klop game starts with 1 round
  }

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
  void startRound(StartRound command) {
    // TODO: validate command! (make generic?)
    final allowance = isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    final event = RoundStarted()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void pauseRound(PauseRound command) {
    // TODO: validate command! (make generic?)
    final allowance = isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    final event = RoundPaused()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void resumeRound(ResumeRound command) {
    // TODO: validate command! (make generic?)
    final allowance = isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    final event = RoundResumed()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void finishRound(FinishRound command) {
    // TODO: validate command! (make generic?)
    final allowance = isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    final event = RoundFinished()
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
  void roundStarted(RoundStarted event) {
    rounds[event.roundIndex].start();
  }

  @eventHandler
  void roundPaused(RoundPaused event) {
    rounds[event.roundIndex].pause();
  }

  @eventHandler
  void roundResumed(RoundResumed event) {
    rounds[event.roundIndex].resume();
  }

  @eventHandler
  void roundFinished(RoundFinished event) {
    rounds[event.roundIndex].finish();
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

  /// Checks whether or not the given command is currently allowed.
  /// This depends on the state of the aggregate and the attribute values of the command itself.
  ///
  /// NOTE: the system can already validate against this method before accepting the actual command,
  /// although the superficial validation should already be done before (we assume it has already been done before calling this method)
  CommandAllowance isAllowed(dynamic command) {
    var roundState = rounds[command.roundIndex].state;
    switch (command.runtimeType) {
      case StrikeOutParticipant:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        if (rounds[command.roundIndex].strikeOutOrder.containsValue(command.participant)) {
          return CommandAllowance(command, false, "Player was already striked out in this round");
        }
        if (!participants.contains(command.participant)) {
          return CommandAllowance(command, false, "Player is not participating in this game");
        }
        return CommandAllowance(command, true, "Strike out player");
      case StartRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        if (participants.isEmpty) {
          return CommandAllowance(command, false, "Round cannot start without any players");
        }
        if (roundState == RoundState.STARTED) {
          return CommandAllowance(command, false, "Round already started");
        }
        if (roundState == RoundState.PAUSED) {
          return CommandAllowance(command, false, "Round has already been started, please resume instead of restart it");
        }
        if (roundState == RoundState.FINISHED) {
          return CommandAllowance(command, false, "Round has already been finished, no going back now");
        }
        return CommandAllowance(command, true, "Start round");
      case PauseRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        if (roundState == RoundState.PAUSED) {
          return CommandAllowance(command, false, "Round has already been paused");
        }
        if (roundState == RoundState.FINISHED) {
          return CommandAllowance(command, false, "Round has already been finished");
        }
        if (roundState == null || roundState == RoundState.NONE) {
          return CommandAllowance(command, false, "Round has not yet been started");
        }
        return CommandAllowance(command, true, "Pause round");
      case ResumeRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        if (roundState != RoundState.PAUSED) {
          return CommandAllowance(command, false, "Round is not paused");
        }
        return CommandAllowance(command, true, "Resume round");
      case FinishRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        // TODO: perhaps add some more logic in order to not finish a round prematurely?
        return CommandAllowance(command, true, "Finish round");

      default:
        return super.isAllowed(command);
    }
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

/// Start a given Round of the Scorable
class StartRound {
  String aggregateId;
  int roundIndex;
}

/// Finish a given Round of the Scorable
class FinishRound {
  String aggregateId;
  int roundIndex;
}

/// Pause a given Round of the Scorable
class PauseRound {
  String aggregateId;
  int roundIndex;
}

/// Resume a given Round of the Scorable
class ResumeRound {
  String aggregateId;
  int roundIndex;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// EVENTS /////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

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

class RoundStarted {
  String aggregateId;
  int roundIndex;
}

class RoundFinished {
  String aggregateId;
  int roundIndex;
}

class RoundPaused {
  String aggregateId;
  int roundIndex;
}

class RoundResumed {
  String aggregateId;
  int roundIndex;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
/// VALUE OBJECTS //////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////


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

  RoundState _state;

  MuurkeKlopNDownRound(int roundIndex) : super(roundIndex);

  RoundState get state => _state;

  void strikeOutParticipant(Participant participant) {
    strikeOutOrder[strikeOutOrder.length] = participant;
  }

  void undoStrikeOutParticipant(Participant participant) {
    strikeOutOrder.removeWhere((strikeOutIndex, strikedOutParticipant) => strikedOutParticipant == participant);
  }

  /// Move a Round to state STARTED.
  /// We don't validate, if the Scorable aggregate wishes to do so, it can still do it by itself...
  void start() {
    _state = RoundState.STARTED;
  }

  /// Move a Round to state PAUSED.
  /// We don't validate, if the Scorable aggregate wishes to do so, it can still do it by itself...
  void pause() {
    _state = RoundState.PAUSED;
  }

  /// Move a Round to state STARTED.
  /// We don't validate, if the Scorable aggregate wishes to do so, it can still do it by itself...
  void resume() {
    _state = RoundState.STARTED;
  }

  /// Move a Round to state FINISHED.
  /// We don't validate, if the Scorable aggregate wishes to do so, it can still do it by itself...
  void finish() {
    _state = RoundState.FINISHED;
  }
}

/// The state of a round.
enum RoundState {
  NONE,
  STARTED,
  PAUSED,
  FINISHED
}
