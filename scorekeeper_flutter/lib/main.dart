import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_example_domain/example.dart';

import 'src/app.dart';
import 'src/services/service.dart';

Future<void> main() async {
  // Create an instance
  final eventStore = EventStoreInMemoryImpl();
  final scorekeeper = Scorekeeper(
      // eventStore: EventStoreInMemoryImpl(),
      eventStore: eventStore,
      aggregateCache: AggregateCacheInMemoryImpl(),
      domainEventFactory: const DomainEventFactory<Scorable>(
          producerId: 'ScorekeeperMain', applicationVersion: 'v1'))
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
    ..registerEventHandler(MuurkeKlopNDownEventHandler());

  final scorekeeperService = ScorekeeperService(scorekeeper);

  // Default data for testing purposes
  final defaultScorable = await scorekeeperService.createNewScorable('Default Game');
  final aggregateId = defaultScorable.aggregateId;
  await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 1');
  await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 2');
  await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 3');
  await scorekeeperService.addRoundToScorable(aggregateId);
  await scorekeeperService.addRoundToScorable(aggregateId);
  await scorekeeperService.addRoundToScorable(aggregateId);
  await scorekeeperService.addRoundToScorable(aggregateId);
  await scorekeeperService.addRoundToScorable(aggregateId);

  // Make sure FlutterFire is initialized
  // https://firebase.flutter.dev/docs/overview/#initializing-flutterfire
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ScorableApp(scorekeeperService));
}
