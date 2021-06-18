
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class _AggregateImpl extends Aggregate {

  _AggregateImpl(AggregateId aggregateId) : super(aggregateId);

}

/// Tests for the Aggregate implementation
void main() {

  group('Aggregate', () {

    late Aggregate aggregate;

    setUp(() {
      aggregate = _AggregateImpl(_AggregateImplId.random());
    });

    /// Events that are being applied within the aggregate, should be stored temporarily
    /// in order for the Scorekeeper application to publish them to the EventManager(s)
    test('Apply event should add the event to the pending events', () {
      final event = Object();
      aggregate.apply(event);
      expect(aggregate.pendingEvents, contains(event));
    });

  });

}

class _AggregateImplId extends AggregateId {

  @override
  final String id;

  @override
  final Type type = _AggregateImpl;

  _AggregateImplId(this.id);

  static _AggregateImplId random() {
    return _AggregateImplId(Uuid().v4());
  }

  static _AggregateImplId of(String id) {
    return _AggregateImplId(id);
  }
}
