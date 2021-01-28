// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';

import 'scorable.dart';

class ScorableCommandHandler implements CommandHandler<Scorable> {
  @override
  bool isConstructorCommand(dynamic command) {
    return command is CreateScorable;
  }

  @override
  Scorable handleConstructorCommand(dynamic command) {
    return Scorable.command(command as CreateScorable);
  }

  @override
  void handle(Scorable scorable, dynamic command) {
    switch (command.runtimeType) {
      case AddParticipant:
        scorable.addParticipant(command as AddParticipant);
        return;
      case RemoveParticipant:
        scorable.removeParticipant(command as RemoveParticipant);
        return;
      case AddRound:
        scorable.addRound(command as AddRound);
        return;
      case StrikeOutParticipant:
        scorable.strikeOutParticipant(command as StrikeOutParticipant);
        return;
      default:
        throw Exception('Unsupported command ${command.runtimeType}.');
    }
  }

  @override
  Scorable newInstance(AggregateId aggregateId) {
    return Scorable.aggregateId(aggregateId);
  }

  @override
  bool handles(dynamic command) {
    switch (command.runtimeType) {
      case CreateScorable:
      case AddParticipant:
      case RemoveParticipant:
      case AddRound:
      case StrikeOutParticipant:
        return true;
      default:
        return false;
    }
  }
}

class ScorableEventHandler implements EventHandler<Scorable> {
  @override
  void handle(Scorable scorable, DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ScorableCreated:
        scorable.handleScorableCreated(event.payload as ScorableCreated);
        return;
      case ParticipantAdded:
        scorable.handleParticipantAdded(event.payload as ParticipantAdded);
        return;
      case ParticipantRemoved:
        scorable.handleParticipantRemoved(event.payload as ParticipantRemoved);
        return;
      case RoundAdded:
        scorable.roundAdded(event.payload as RoundAdded);
        return;
      case ParticipantStrikedOut:
        scorable.participantStrikedOut(event.payload as ParticipantStrikedOut);
        return;
      default:
        throw Exception('Unsupported event ${event.payload.runtimeType}.');
    }
  }

  @override
  bool forType(Type type) {
    return type == Scorable;
  }

  @override
  Scorable newInstance(AggregateId aggregateId) {
    return Scorable.aggregateId(aggregateId);
  }

  @override
  bool handles(DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ScorableCreated:
      case ParticipantAdded:
      case ParticipantRemoved:
      case RoundAdded:
      case ParticipantStrikedOut:
        return true;
      default:
        return false;
    }
  }
}
