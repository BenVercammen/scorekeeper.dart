import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_example_domain/example.dart';

import 'src/app.dart';
import 'src/services/service.dart';

void main() async {
  // Create an instance
  final scorekeeper = Scorekeeper(eventStore: EventStoreInMemoryImpl(), aggregateCache: AggregateCacheInMemoryImpl())
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
    ..registerEventHandler(MuurkeKlopNDownEventHandler());

  final scorekeeperService = ScorekeeperService(scorekeeper);

  // Default data for testing purposes
  final defaultScorable = scorekeeperService.createNewScorable('Default Game');
  final aggregateId = defaultScorable.aggregateId;
  scorekeeperService
    ..addParticipantToScorable(aggregateId, 'Player 1')
    ..addParticipantToScorable(aggregateId, 'Player 2')
    ..addParticipantToScorable(aggregateId, 'Player 3')
    ..addRoundToScorable(aggregateId)
    ..addRoundToScorable(aggregateId)
    ..addRoundToScorable(aggregateId)
    ..addRoundToScorable(aggregateId)
    ..addRoundToScorable(aggregateId);

  // Make sure FlutterFire is initialized
  // https://firebase.flutter.dev/docs/overview/#initializing-flutterfire
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ScorableApp(scorekeeperService));
}
