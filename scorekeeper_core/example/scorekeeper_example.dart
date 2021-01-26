import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:uuid/uuid.dart';

void main() {

  // Create an instance
  final scorekeeper = Scorekeeper(
      eventStore: EventStoreInMemoryImpl(),
      aggregateCache: AggregateCacheInMemoryImpl())
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
  final scorable = scorekeeper.getCachedAggregateDtoById<ScorableDto>(aggregateId);


  // Work with the Scorable...
  // TODO: this Scorable should be a DTO instead of the actual aggregate! no?
  /// de gegenereerde code aanpassen...
  /// op zich moet de scorekeeper nog wel aan de aggregate kunnen
  /// het is de "client" van de scorekeeper die met DTO's moet werken (dus een van @handler methodes gestripte versie)
  ///
  /// eigenlijk is het aan die handlers om alles af te schermen!
  ///   ->
  ///
  ///
  //  of alle handler methodes moeten private zijn... maar dat gaat dan weer niet omdat die scorable.g.dart een aparte file / package is
  //  tenzij ik daar ook alles in kopieer en enkel die deel... en de scorable.dart file zelf niet... (exposen via example.dart file)
  // We don't want the aggregates to leave the domain...
  //
  //
  //
  print(scorable.participants.length);

}

