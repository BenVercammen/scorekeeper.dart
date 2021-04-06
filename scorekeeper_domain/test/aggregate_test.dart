
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';

class _AggregateImpl extends Aggregate {

  _AggregateImpl(AggregateId aggregateId) : super(aggregateId);

}

/// Tests for the Aggregate implementation
void main() {

  group('Aggregate', () {

    late Aggregate aggregate;

    setUp(() {
      aggregate = _AggregateImpl(AggregateId.random());
    });

    /// Events that are being applied within the aggregate, should be stored temporarily
    /// in order for the Scorekeeper application to publish them to the EventManager(s)
    test('Apply event should add the event to the applied events', () {
      final event = Object();
      aggregate.apply(event);
      expect(aggregate.appliedEvents, contains(event));
    });

  });

}
