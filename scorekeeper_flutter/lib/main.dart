import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_event_store_moor/event_store_moor.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';

import 'src/app.dart';
import 'src/services/service.dart';

Future<void> main({String? pDbFilename}) async {
  // Make sure flutter is initialized (ServicesBinding.instance is null otherwise)
  WidgetsFlutterBinding.ensureInitialized();

  // Create a Scorekeeper instance

  final domainSerializer = ScorableSerializer();
  final domainDeserializer = ScorableDeserializer();
  final eventStore = EventStoreMoorImpl(domainSerializer, domainDeserializer,
      dbFilename: pDbFilename ?? 'db.sqlite');
  // final eventStore = EventStoreInMemoryImpl();
  final aggregateCache = AggregateCacheInMemoryImpl();

  final scorekeeper = Scorekeeper(
      eventStore: eventStore,
      aggregateCache: aggregateCache,
      aggregateDtoFactory: AggregateDtoFactory(),
      domainEventFactory: const DomainEventFactory<MuurkeKlopNDown>(
          producerId: 'ScorekeeperMain', applicationVersion: 'v1'))
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
    ..registerEventHandler(MuurkeKlopNDownEventHandler());

  final scorekeeperService = ScorekeeperService(scorekeeper);

  // // Default data for testing purposes
  // final defaultScorable = await scorekeeperService.createNewScorable('Default Game');
  // final aggregateId = defaultScorable.aggregateId;
  // await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 1');
  // await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 2');
  // await scorekeeperService.addParticipantToScorable(aggregateId, 'Player 3');
  // await scorekeeperService.addRoundToScorable(aggregateId);
  // await scorekeeperService.addRoundToScorable(aggregateId);
  // await scorekeeperService.addRoundToScorable(aggregateId);
  // await scorekeeperService.addRoundToScorable(aggregateId);
  // await scorekeeperService.addRoundToScorable(aggregateId);

  // Make sure FlutterFire is initialized
  // https://firebase.flutter.dev/docs/overview/#initializing-flutterfire
  await Firebase.initializeApp();
  runApp(ScorableApp(scorekeeperService));
}
