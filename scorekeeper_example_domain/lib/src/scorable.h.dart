// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/src/scorable.dart';

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
        return true;
      default:
        return false;
    }
  }
}
