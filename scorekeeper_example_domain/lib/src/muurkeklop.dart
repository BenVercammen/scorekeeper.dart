
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
    final event = RoundStarted()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void pauseRound(PauseRound command) {
    final event = RoundPaused()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void resumeRound(ResumeRound command) {
    final event = RoundResumed()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void finishRound(FinishRound command) {
    final event = RoundFinished()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void strikeOutParticipant(StrikeOutParticipant command) {
    final event = ParticipantStruckOut()
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
    rounds[event.roundIndex]!.start();
  }

  @eventHandler
  void roundPaused(RoundPaused event) {
    rounds[event.roundIndex]!.pause();
  }

  @eventHandler
  void roundResumed(RoundResumed event) {
    rounds[event.roundIndex]!.resume();
  }

  @eventHandler
  void roundFinished(RoundFinished event) {
    rounds[event.roundIndex]!.finish();
  }

  @eventHandler
  void participantStruckOut(ParticipantStruckOut event) {
    final round = rounds[event.roundIndex]!;
    round.strikeOutParticipant(event.participant);
  }

  @eventHandler
  void participantStrikeOutUndone(ParticipantStrikeOutUndone event) {
    final round = rounds[event.roundIndex]!;
    round.undoStrikeOutParticipant(event.participant);
  }

  /// Checks whether or not the given command is currently allowed.
  /// This depends on the state of the aggregate and the attribute values of the command itself.
  ///
  /// NOTE: the system can already validate against this method before accepting the actual command,
  /// although the superficial validation should already be done before (we assume it has already been done before calling this method)
  CommandAllowance isAllowed(dynamic command) {
    switch (command.runtimeType) {
      case StrikeOutParticipant:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        final round = rounds[command.roundIndex]!;
        if (round.state != RoundState.STARTED) {
          return CommandAllowance(command, false, "Round is not in progress");
        }
        if (round.isStruckOut(command.participant)) {
          return CommandAllowance(command, false, "${command.participant.name} was already struck out in round ${command.roundIndex + 1}");
        }
        if (!isParticipating(command.participant)) {
          return CommandAllowance(command, false, "Player is not participating in this game");
        }
        return CommandAllowance(command, true, "Strike out player");
      case UndoParticipantStrikeOut:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        final round = rounds[command.roundIndex]!;
        if (round.state != RoundState.STARTED) {
          return CommandAllowance(command, false, "Round is not in progress");
        }
        return CommandAllowance(command, true, "Undo player struck out");
      case StartRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        if (participants.isEmpty) {
          return CommandAllowance(command, false, "Round cannot start without any players");
        }
        final roundState = rounds[command.roundIndex]!.state;
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
        final roundState = rounds[command.roundIndex]!.state;
        if (roundState == RoundState.PAUSED) {
          return CommandAllowance(command, false, "Round has already been paused");
        }
        if (roundState == RoundState.FINISHED) {
          return CommandAllowance(command, false, "Round has already been finished");
        }
        if (roundState == RoundState.NONE) {
          return CommandAllowance(command, false, "Round has not yet been started");
        }
        return CommandAllowance(command, true, "Pause round");
      case ResumeRound:
        if (!rounds.containsKey(command.roundIndex)) {
          return CommandAllowance(command, false, "Round with index ${command.roundIndex} does not exist");
        }
        final roundState = rounds[command.roundIndex]!.state;
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

  /// Check if the given participant is participating in this Scorable
  bool isParticipating(Participant participant) {
    return participants.contains(participant);
  }


}



///////////////////////////////////////////////////////////////////////////////////////////////////////
/// COMMANDS///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

/// When a participant strikes out, he/she will receive a fixed number of points depending
/// on the order in which he was struck out.
class StrikeOutParticipant {
  late String aggregateId;
  late Participant participant;
  late int roundIndex;
}

class UndoParticipantStrikeOut {
  late String aggregateId;
  late Participant participant;
  late int roundIndex;
}

/// Add an extra Round to the Scorable
class AddRound {
  late String aggregateId;
}

/// Remove an existing Round from the Scorable
class RemoveRound {
  late String aggregateId;
  late int roundIndex;
}

/// Start a given Round of the Scorable
class StartRound {
  late String aggregateId;
  late int roundIndex;
}

/// Finish a given Round of the Scorable
class FinishRound {
  late String aggregateId;
  late int roundIndex;
}

/// Pause a given Round of the Scorable
class PauseRound {
  late String aggregateId;
  late int roundIndex;
}

/// Resume a given Round of the Scorable
class ResumeRound {
  late String aggregateId;
  late int roundIndex;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// EVENTS /////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

class ParticipantStruckOut {
  late String aggregateId;
  late Participant participant;
  late int roundIndex;
}

class ParticipantStrikeOutUndone {
  late String aggregateId;
  late Participant participant;
  late int roundIndex;
}

class RoundAdded {
  late String aggregateId;
  late int roundIndex;
}

class RoundRemoved {
  late String aggregateId;
  late int roundIndex;
}

class RoundStarted {
  late String aggregateId;
  late int roundIndex;
}

class RoundFinished {
  late String aggregateId;
  late int roundIndex;
}

class RoundPaused {
  late String aggregateId;
  late int roundIndex;
}

class RoundResumed {
  late String aggregateId;
  late int roundIndex;
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

  RoundState _state = RoundState.NONE;

  MuurkeKlopNDownRound(int roundIndex) : super(roundIndex);

  RoundState get state => _state;

  void strikeOutParticipant(Participant participant) {
    strikeOutOrder[strikeOutOrder.length] = participant;
  }

  void undoStrikeOutParticipant(Participant participant) {
    strikeOutOrder.removeWhere((strikeOutIndex, struckOutParticipant) => struckOutParticipant == participant);
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

  /// Check if the given participant is already struck out in this round
  bool isStruckOut(Participant participant) {
    return strikeOutOrder.values.contains(participant);
  }
}

/// The state of a round.
enum RoundState {
  /// The round has no predefined state
  NONE,
  /// The round is ready to start
  // TODO: READY_TO_START,
  /// The round is already started
  STARTED,
  /// The round is paused
  PAUSED,
  /// The round is finished
  FINISHED
}
