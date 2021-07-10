import 'dart:io';

import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/src/scorekeeper_base.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart' hide AggregateDtoFactory;
import 'package:scorekeeper_domain_scorable/scorable.dart' as s show AggregateDtoFactory;
import 'package:scorekeeper_event_store_moor/event_store_moor.dart';
import 'package:scorekeeper_flutter/src/services/service.dart';
import 'package:test/test.dart';

/// Testing the ScorekeeperService
void main() {
  group('ScorekeeperService', () {
    // The unit under test
    late ScorekeeperService scorekeeperService;

    // The Scorekeeper instance to be injected in the ScorekeeperService
    late Scorekeeper _scorekeeper;

    setUp(() {
      _scorekeeper = Scorekeeper(
          eventStore: EventStoreInMemoryImpl(),
          aggregateCache: AggregateCacheInMemoryImpl(),
          aggregateDtoFactory: s.AggregateDtoFactory(),
          domainEventFactory: const DomainEventFactory<Scorable>(
              producerId: 'service_test', applicationVersion: 'v1'))
        // Register the command and event handlers for the relevant domain
        ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
        ..registerEventHandler(MuurkeKlopNDownEventHandler());
      scorekeeperService = ScorekeeperService(_scorekeeper);
    });

    group('loadScorables', () {
      /// We want to be able to pull scorables from the ScoreKeeper (write) or ScorableProjection (read) ...
      /// TODO: still need to decide on which one we'll use, though we'll probably stay with the write model..
      test('loadScorables in reversed chronological order', () async {
        final registeredAggregateIds = List.empty(growable: true);
        // Given 20 Registered AggregateIds
        // (Aggregates the current instance is interested in, in this case because it created them itself)
        for (var i = 1; i <= 20; i++) {
          final aggregateId = AggregateId.random(Scorable);
          await _scorekeeper.handleCommand(CreateScorable()
            ..scorableId = aggregateId.id
            ..name = 'Aggregate $i');
          sleep(const Duration(milliseconds: 1));
          registeredAggregateIds.add(aggregateId);
        }
        // When we want to load a limited list of aggregateIds..
        final registeredScorablesPage = await scorekeeperService.loadScorables(
            0, 5);
        // Then we should get the 5 latest aggregateIds because they were modified last
        expect(registeredScorablesPage.length, equals(5));
        final pagedItems = List.of(registeredScorablesPage);
        expect(pagedItems[0].name, equals('Aggregate 20'));
        expect(pagedItems[1].name, equals('Aggregate 19'));
        expect(pagedItems[2].name, equals('Aggregate 18'));
        expect(pagedItems[3].name, equals('Aggregate 17'));
        expect(pagedItems[4].name, equals('Aggregate 16'));
      });

      /// So, this test was created because we were struggling with the following issue:
      ///   ``LateInitializationError: Field 'name' has not been initialized.``
      /// The root of the problem was the fact that we've added ``AggregateType`` to the ``AggregateId``
      /// but because of inheritance, it's tricky to determine which type to use (eg: ``Scorable`` or ``MuurkeKlopNDown``)
      test('createScorable', () async {
        final result = scorekeeperService.createNewScorable(
            'Test', MuurkeKlopNDown);
        final dto = await result;
        expect(dto.name, equals('Test'));
      });
    });

    /// Tests using the EventStoreMoorImpl.
    /// This implementation is causing some issues because not everything is kept in memory.
    /// So specific bugs could be reproduced and fixed using this setup.
    group('EventStoreMoorImpl', () {

      setUp(() async {
        final domainSerializer = ScorableSerializer();
        final domainDeserializer = ScorableDeserializer();
        final eventStore = EventStoreMoorImpl(domainSerializer, domainDeserializer, allowClear: true);
        await eventStore.clear();
        final registeredAggregates = await eventStore.registeredAggregateIds().toList();
        expect(registeredAggregates.length, equals(0));
        _scorekeeper = Scorekeeper(
            eventStore: eventStore,
            aggregateCache: AggregateCacheInMemoryImpl(),
            aggregateDtoFactory: s.AggregateDtoFactory(),
            domainEventFactory: const DomainEventFactory<Scorable>(
                producerId: 'service_test', applicationVersion: 'v1'))
        // Register the command and event handlers for the relevant domain
          ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
          ..registerEventHandler(MuurkeKlopNDownEventHandler());
        scorekeeperService = ScorekeeperService(_scorekeeper);
      });

      /// Due to a bug in the generated deserializer class,
      /// we'd end up with AggregateId's that weren't correct after loading them through the
      /// EventStoreMoorImpl instance.
      /// This has been fixed, but we keep this test here just in case...
      test('loadScorables should maintain the same aggregateId after creation', () async {
        final first = await scorekeeperService.loadScorables(0, 10);
        expect(first.length, equals(0));
        final created = await scorekeeperService.createNewScorable('Test 1', MuurkeKlopNDown);
        final isRegistered1 = await _scorekeeper.isRegistered(created.aggregateId);
        final second = await scorekeeperService.loadScorables(0, 10);
        expect(second.length, equals(1));
        expect(second.first.aggregateId, equals(created.aggregateId));
        // TODO: check equals value!??? When do they have to be equal?? generate equals/hashcode methods?
        // expect(second.first, equals(created));
      });

    });

  });
}
