// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';

import 'muurkeklop.dart';
import 'scorable.dart';

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
    switch (command.runtimeType) {
      case AddRound:
        muurkeKlopNDown.addRound(command as AddRound);
        return;
      case RemoveRound:
        muurkeKlopNDown.removeRound(command as RemoveRound);
        return;
      case StrikeOutParticipant:
        muurkeKlopNDown.strikeOutParticipant(command as StrikeOutParticipant);
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
      case StrikeOutParticipant:
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
      case ParticipantStrikedOut:
        muurkeKlopNDown
            .participantStrikedOut(event.payload as ParticipantStrikedOut);
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
      case ParticipantStrikedOut:
      case ScorableCreated:
      case ParticipantAdded:
      case ParticipantRemoved:
        return true;
      default:
        return false;
    }
  }
}
