// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/src/scorable.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.dart';

class MuurkeKlopNDownCommandHandler implements CommandHandler<MuurkeKlopNDown> {
  @override
  bool isConstructorCommand(dynamic command) {
    return command is CreateScorable;
  }

  @override
  MuurkeKlopNDown handleConstructorCommand(dynamic command) {
    return MuurkeKlopNDown.command(command as CreateScorable);
  }

  @override
  void handle(MuurkeKlopNDown muurkeKlopNDown, dynamic command) {
    // Validate the incoming command (allowance)
    final allowance = muurkeKlopNDown.isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    switch (command.runtimeType) {
      case AddRound:
        muurkeKlopNDown.addRound(command as AddRound);
        return;
      case RemoveRound:
        muurkeKlopNDown.removeRound(command as RemoveRound);
        return;
      case StartRound:
        muurkeKlopNDown.startRound(command as StartRound);
        return;
      case PauseRound:
        muurkeKlopNDown.pauseRound(command as PauseRound);
        return;
      case ResumeRound:
        muurkeKlopNDown.resumeRound(command as ResumeRound);
        return;
      case FinishRound:
        muurkeKlopNDown.finishRound(command as FinishRound);
        return;
      case StrikeOutParticipant:
        muurkeKlopNDown.strikeOutParticipant(command as StrikeOutParticipant);
        return;
      case UndoParticipantStrikeOut:
        muurkeKlopNDown
            .undoParticipantStrikeout(command as UndoParticipantStrikeOut);
        return;
      case AddParticipant:
        muurkeKlopNDown.addParticipant(command as AddParticipant);
        return;
      case RemoveParticipant:
        muurkeKlopNDown.removeParticipant(command as RemoveParticipant);
        return;
      default:
        throw Exception('Unsupported command ${command.runtimeType}.');
    }
  }

  @override
  MuurkeKlopNDown newInstance(AggregateId aggregateId) {
    return MuurkeKlopNDown.aggregateId(aggregateId);
  }

  @override
  bool handles(dynamic command) {
    switch (command.runtimeType) {
      case CreateScorable:
      case AddRound:
      case RemoveRound:
      case StartRound:
      case PauseRound:
      case ResumeRound:
      case FinishRound:
      case StrikeOutParticipant:
      case UndoParticipantStrikeOut:
      case AddParticipant:
      case RemoveParticipant:
        return true;
      default:
        return false;
    }
  }
}

class MuurkeKlopNDownEventHandler implements EventHandler<MuurkeKlopNDown> {
  @override
  void handle(MuurkeKlopNDown muurkeKlopNDown, DomainEvent event) {
    switch (event.payload.runtimeType) {
      case RoundAdded:
        muurkeKlopNDown.roundAdded(event.payload as RoundAdded);
        return;
      case RoundRemoved:
        muurkeKlopNDown.roundRemoved(event.payload as RoundRemoved);
        return;
      case RoundStarted:
        muurkeKlopNDown.roundStarted(event.payload as RoundStarted);
        return;
      case RoundPaused:
        muurkeKlopNDown.roundPaused(event.payload as RoundPaused);
        return;
      case RoundResumed:
        muurkeKlopNDown.roundResumed(event.payload as RoundResumed);
        return;
      case RoundFinished:
        muurkeKlopNDown.roundFinished(event.payload as RoundFinished);
        return;
      case ParticipantStruckOut:
        muurkeKlopNDown
            .participantStruckOut(event.payload as ParticipantStruckOut);
        return;
      case ParticipantStrikeOutUndone:
        muurkeKlopNDown.participantStrikeOutUndone(
            event.payload as ParticipantStrikeOutUndone);
        return;
      case ScorableCreated:
        muurkeKlopNDown.handleScorableCreated(event.payload as ScorableCreated);
        return;
      case ParticipantAdded:
        muurkeKlopNDown
            .handleParticipantAdded(event.payload as ParticipantAdded);
        return;
      case ParticipantRemoved:
        muurkeKlopNDown
            .handleParticipantRemoved(event.payload as ParticipantRemoved);
        return;
      default:
        throw Exception('Unsupported event ${event.payload.runtimeType}.');
    }
  }

  @override
  bool forType(Type type) {
    return type == MuurkeKlopNDown;
  }

  @override
  MuurkeKlopNDown newInstance(AggregateId aggregateId) {
    return MuurkeKlopNDown.aggregateId(aggregateId);
  }

  @override
  bool handles(DomainEvent event) {
    switch (event.payload.runtimeType) {
      case RoundAdded:
      case RoundRemoved:
      case RoundStarted:
      case RoundPaused:
      case RoundResumed:
      case RoundFinished:
      case ParticipantStruckOut:
      case ParticipantStrikeOutUndone:
      case ScorableCreated:
      case ParticipantAdded:
      case ParticipantRemoved:
        return true;
      default:
        return false;
    }
  }
}
