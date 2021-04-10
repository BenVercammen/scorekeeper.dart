import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/src/scorekeeper_base.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_flutter/src/services/service.dart';

/// Testing the ScorekeeperService
void main() {
  group('ScorekeeperService', () {
    // The unit under test
    late ScorekeeperService scorekeeperService;

    // The Scorekeeper instance to be injected in the ScorekeeperService
    late Scorekeeper _scorekeeper;

    setUp(() {
      _scorekeeper = Scorekeeper(eventStore: EventStoreInMemoryImpl(), aggregateCache: AggregateCacheInMemoryImpl())
        // Register the command and event handlers for the relevant domain
        ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
        ..registerEventHandler(MuurkeKlopNDownEventHandler());
      scorekeeperService = ScorekeeperService(_scorekeeper);
    });

    /// We want to be able to pull scorables from the ScoreKeeper (write) or ScorableProjection (read) ...
    /// TODO: still need to decide on which one we'll use, though we'll probably stay with the write model..
    test('loadScorables', () {
      final registeredAggregateIds = List.empty(growable: true);
      // Given 20 Registered AggregateIds
      // (Aggregates the current instance is interested in, in this case because it created them itself)
      for (var i = 1; i <= 20; i++) {
        final aggregateId = AggregateId.random();
        _scorekeeper.handleCommand(CreateScorable()
          ..aggregateId = aggregateId.id
          ..name = 'Aggregate $i');
        sleep(const Duration(milliseconds: 1));
        registeredAggregateIds.add(aggregateId);
      }
      // When we want to load a limited list of aggregateIds..
      final registeredScorablesPage = scorekeeperService.loadScorables(0, 5);
      // Then we should get the 5 latest aggregateIds because they were modified last
      expect(registeredScorablesPage.length, equals(5));
      final pagedItems = List.of(registeredScorablesPage);
      expect(pagedItems[0].name, equals('Aggregate 20'));
      expect(pagedItems[1].name, equals('Aggregate 19'));
      expect(pagedItems[2].name, equals('Aggregate 18'));
      expect(pagedItems[3].name, equals('Aggregate 17'));
      expect(pagedItems[4].name, equals('Aggregate 16'));
    });
  });
}
