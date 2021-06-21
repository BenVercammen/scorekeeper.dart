
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';

/// Tests for the AggregateCache implementation(s)
void main() {

  group('AggregateCache', () {

    late AggregateCache aggregateCache;

    setUp(() {
      aggregateCache = AggregateCacheInMemoryImpl();
    });

    test('Test store, remove and contains aggregate', () {
      final aggregate1 = TestAggregate(AggregateId.random(TestAggregate));
      final aggregate2 = TestAggregate(AggregateId.random(TestAggregate));
      aggregateCache.store(aggregate1);
      expect(aggregateCache.contains(aggregate1.aggregateId), equals(true));
      expect(aggregateCache.contains(aggregate2.aggregateId), equals(false));
      aggregateCache.purge(aggregate1.aggregateId);
      expect(aggregateCache.contains(aggregate1.aggregateId), equals(false));
    });

  });

}

class TestAggregate extends Aggregate {
  late String name;
  TestAggregate(AggregateId aggregateId) : super(aggregateId);
}
