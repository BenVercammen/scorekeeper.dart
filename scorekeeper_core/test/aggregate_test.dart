
import 'package:example_domain/example.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';

import '../lib/src/aggregate.dart';

/// Tests for the AggregateCache implementation(s)
void main() {

  group('AggregateCache', () {

    AggregateCache aggregateCache;

    setUp(() {
      aggregateCache = AggregateCacheImpl();
    });

    test('Test store, remove and contains aggregate', () {
      final aggregate1 = Scorable.aggregateId(AggregateId.random());
      final aggregate2 = Scorable.aggregateId(AggregateId.random());
      aggregateCache.store(aggregate1);
      expect(aggregateCache.contains(aggregate1.aggregateId), equals(true));
      expect(aggregateCache.contains(aggregate2.aggregateId), equals(false));
      aggregateCache.purge(aggregate1.aggregateId);
      expect(aggregateCache.contains(aggregate1.aggregateId), equals(false));
    });

  });

}


