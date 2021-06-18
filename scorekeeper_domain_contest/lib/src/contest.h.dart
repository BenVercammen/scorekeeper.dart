// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_contest/src/contest.d.dart';
import 'package:scorekeeper_domain/src/aggregate.dart';
import 'package:scorekeeper_domain_contest/src/contest.dart';
import 'package:scorekeeper_domain_contest/src/generated/events.pb.dart';

class ContestCommandHandler
    implements CommandHandler<Contest, ContestAggregateId> {
  @override
  bool isConstructorCommand(dynamic command) {
    return command is CreateContest;
  }

  @override
  Contest handleConstructorCommand(dynamic command) {
    return Contest.command(command as CreateContest);
  }

  @override
  void handle(Contest contest, dynamic command) {
    // Validate the incoming command (allowance)
    final allowance = contest.isAllowed(command);
    if (!allowance.isAllowed) {
      throw Exception(allowance.reason);
    }
    switch (command.runtimeType) {
      case AddParticipant:
        contest.addParticipant(command as AddParticipant);
        return;
      case RemoveParticipant:
        contest.removeParticipant(command as RemoveParticipant);
        return;
      case AddStage:
        contest.addStage(command as AddStage);
        return;
      case AddScorable:
        contest.addScorable(command as AddScorable);
        return;
      default:
        throw Exception('Unsupported command ${command.runtimeType}.');
    }
  }

  @override
  Contest newInstance(ContestAggregateId contestAggregateId) {
    return Contest.aggregateId(contestAggregateId);
  }

  @override
  bool handles(dynamic command) {
    switch (command.runtimeType) {
      case CreateContest:
      case AddParticipant:
      case RemoveParticipant:
      case AddStage:
      case AddScorable:
        return true;
      default:
        return false;
    }
  }
}

class ContestEventHandler implements EventHandler<Contest, ContestAggregateId> {
  @override
  void handle(Contest contest, DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ContestCreated:
        contest.handleContestCreated(event.payload as ContestCreated);
        return;
      case ParticipantAdded:
        contest.handleParticipantAdded(event.payload as ParticipantAdded);
        return;
      case ParticipantRemoved:
        contest.handleParticipantRemoved(event.payload as ParticipantRemoved);
        return;
      default:
        throw Exception('Unsupported event ${event.payload.runtimeType}.');
    }
  }

  @override
  bool forType(Type type) {
    return type == Contest;
  }

  @override
  Contest newInstance(ContestAggregateId contestAggregateId) {
    return Contest.aggregateId(contestAggregateId);
  }

  @override
  bool handles(DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ContestCreated:
      case ParticipantAdded:
      case ParticipantRemoved:
        return true;
      default:
        return false;
    }
  }
}
