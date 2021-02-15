
import 'package:flutter_test/flutter_test.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/src/scorekeeper_base.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_flutter/service.dart';

void main() {
  group('ScorekeeperService', () {

    // The unit under test
    ScorekeeperService scorekeeperService;

    // The Scorekeeper instance to be injected in the ScorekeeperService
    Scorekeeper _scorekeeper;

    setUp(() {
      _scorekeeper = Scorekeeper(
          eventStore: EventStoreInMemoryImpl(),
          aggregateCache: AggregateCacheInMemoryImpl())
      // Register the command and event handlers for the relevant domain
        ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
        ..registerEventHandler(MuurkeKlopNDownEventHandler()
        );
      final _scorableProjection = ScorableProjection();
      scorekeeperService = ScorekeeperService(_scorekeeper);
    });

    /// We want to be able to pull scorables from the ScoreKeeper (write) or ScorableProjection (read) ...
    /// TODO: still need to decide on which one we'll use, though we'll probably stay with the write model..
    test('loadScorables', () {
      final registeredAggregateIds = List.empty(growable: true);
      // Given 20 Registered AggregateIds
      // (Aggregates the current instance is interested in, in this case because it created them itself)
      for (var i = 0; i < 20; i++) {
        final aggregateId = AggregateId.random();
        _scorekeeper.handleCommand(CreateScorable()
            ..aggregateId = aggregateId.id
            ..name = 'Aggregate $i'
        );
        registeredAggregateIds.add(aggregateId);
      }
      // When we want to load a limited list of aggregateIds..
      var registeredScorablesPage = scorekeeperService.loadScorables(0, 5);
      // Then we should get the 5 latest aggregateIds because they were modified last
      expect(registeredScorablesPage.length, equals(5));
      expect(registeredScorablesPage.first.aggregateId, equals(registeredAggregateIds.last));
      expect(registeredScorablesPage, containsAllInOrder(registeredAggregateIds.getRange(14, 19)));
    });
  });
}
