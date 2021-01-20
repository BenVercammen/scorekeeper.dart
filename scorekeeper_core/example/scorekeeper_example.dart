import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:uuid/uuid.dart';

void main() {

  // Create an instance
  final scorekeeper = Scorekeeper(EventManagerInMemoryImpl(), null, AggregateCacheImpl())
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(ScorableCommandHandler())
    ..registerEventHandler(ScorableEventHandler());

  final aggregateId = AggregateId.random();

  // Handle a command
  final createScorableCommand = CreateScorable()
    ..aggregateId = aggregateId.id
    ..name = 'Test Scorable 1';
  scorekeeper.handleCommand(createScorableCommand);

  // Handle another command
  final participant = Participant()
    ..participantId = Uuid().v4()
    ..name = 'Player One';
  final addParticipantCommand = AddParticipant()
    ..aggregateId = aggregateId.id
    ..participant = participant;
  scorekeeper.handleCommand(addParticipantCommand);

  // Retrieve (cached) aggregate
  final scorable = scorekeeper.getAggregateById<Scorable>(aggregateId);

  // Work with the Scorable...
  // TODO: this Scorable should be a DTO instead of the actual aggregate!
  // We don't want the aggregates to leave the domain...
  print(scorable.participants.length);

}

