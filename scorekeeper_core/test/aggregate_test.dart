
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

    /// This test was written when we discovered that the combination of ``EventStoreMoorImpl`` and ``AggregateCacheInMemoryImpl``
    /// was giving issues with the lastModified time being ``null``.
    test("Aggregate's lastModified should be stored", () {
      final aggregate1 = TestAggregate(AggregateId.random(TestAggregate));
      expect(aggregate1.lastModified, isNotNull);
      /// TODO: probleem is mogelijks te wijten aan het feit dat we in de Aggregate die lastModified enkel zetten tijdens "apply(event)"
      /// maar dan nog, die combo is het probleem he, nie? :/
      /// waarom werkt dat met InMemory wel? Omdat dat zelfde references zijn??
    });

  });

}

class TestAggregate extends Aggregate {
  late String name;
  TestAggregate(AggregateId aggregateId) : super(aggregateId);
}
