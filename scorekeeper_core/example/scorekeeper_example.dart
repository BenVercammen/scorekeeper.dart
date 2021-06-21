import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';

import 'example_domain.dart';


void main() async {

  // TODO: terug opzetten!!

  // // Create an instance
  // final scorekeeper = Scorekeeper(
  //     eventStore: EventStoreInMemoryImpl(),
  //     aggregateCache: AggregateCacheInMemoryImpl(),
  //     domainEventFactory: DomainEventFactory<Scorable>(producerId: 'example', applicationVersion: 'v1'))
  //   // Register the command and event handlers for the relevant domain
  //   ..registerCommandHandler(ScorableCommandHandler())
  //   ..registerEventHandler(ScorableEventHandler());
  //
  // final aggregateId = AggregateId.random();
  //
  // // Handle a command
  // final createScorableCommand = CreateScorable()
  //   ..scorableId = aggregateId.aggregateId
  //   ..name = 'Test Scorable 1';
  // await scorekeeper.handleCommand(createScorableCommand);
  //
  // // Handle another command
  // final participant = Participant(participantId: AggregateId.random(), participantName: 'Player One');
  // final addParticipantCommand = AddParticipant()
  //   ..scorableId = aggregateId.scorableId
  //   ..participant = participant;
  // await scorekeeper.handleCommand(addParticipantCommand);
  //
  // // Retrieve (cached) aggregate
  // final scorable = await scorekeeper.getCachedAggregateDtoById<ScorableDto>(aggregateId);
  //
  // // Query the Scorable aggregate DTO...
  // print(scorable.participants);

}

