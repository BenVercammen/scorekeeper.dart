import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:uuid/uuid.dart';

void main() async {

  // Create an instance
  final scorekeeper = Scorekeeper(
      eventStore: EventStoreInMemoryImpl(),
      aggregateCache: AggregateCacheInMemoryImpl(),
    domainEventFactory: DomainEventFactory<Scorable, ScorableAggregateId>(producerId: 'example', applicationVersion: 'v1'))
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(ScorableCommandHandler())
    ..registerEventHandler(ScorableEventHandler());

  final aggregateId = ScorableAggregateId.random();

  // Handle a command
  final createScorableCommand = CreateScorable()
    ..scorableId = aggregateId.scorableId
    ..name = 'Test Scorable 1';
  await scorekeeper.handleCommand(createScorableCommand);

  // Handle another command
  final participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player One');
  final addParticipantCommand = AddParticipant()
    ..scorableId = aggregateId.scorableId
    ..participant = participant;
  await scorekeeper.handleCommand(addParticipantCommand);

  // Retrieve (cached) aggregate
  final scorable = await scorekeeper.getCachedAggregateDtoById<ScorableDto>(aggregateId);

  // Query the Scorable aggregate DTO...
  print(scorable.participants);

}

