import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';

/// Tests for the EventStore implementation(s)
///  - EventStoreInMemoryImpl: just keep everything in memory. Okay for testing and a small number of events, but won't scale...
///  - EventStoreLocalStorageImpl: make sure all events are persisted in local storage
///
/// The EventStore just stores local and remote events, no more, no less!
/// The AggregateCache will keep everything in memory (state, snapshots, ...)
/// The EventStore should just be able to read and write/append events.
///
///
void main() {
  late EventStore eventStore;
  late DomainEventFactory domainEventFactory;

  final aggregateId1 = AggregateId.of("101");
  final aggregateId2 = AggregateId.of("102");
  final aggregateId3 = AggregateId.of("103");
  final eventId1 = 'eventId1';

  /// For InMemoryImpl it's simple...
  group('EventStoreInMemoryImpl', () {
    setUp(() {
      domainEventFactory = DomainEventFactory(
          producerId: 'prodId', applicationVersion: 'appVersion');
      // Instantiate EventStore
      eventStore = EventStoreInMemoryImpl();
      // Register Aggregates so the events are being stored
      eventStore.registerAggregateId(aggregateId1);
      eventStore.registerAggregateId(aggregateId2);
      eventStore.registerAggregateId(aggregateId3);
    });

    group('READ', () {
      test('Event should be stored and retrievable', () {
        var domainEvent1 = domainEventFactory.remote(
            eventId1, aggregateId1, 0, DateTime.now(), "payload");
        eventStore.storeDomainEvent(domainEvent1);
        expect(eventStore.getAllDomainEvents(), contains(domainEvent1));
      });

      test('Retrieve all stored events by aggregateId', () {
        eventStore.storeDomainEvent(domainEventFactory.remote(
            'eventId1', aggregateId1, 0, DateTime.now(), "payload"));
        eventStore.storeDomainEvent(domainEventFactory.remote(
            'eventId2', aggregateId1, 1, DateTime.now(), "payload"));
        eventStore.storeDomainEvent(domainEventFactory.remote(
            'eventId3', aggregateId1, 2, DateTime.now(), "payload"));
        eventStore.storeDomainEvent(domainEventFactory.remote(
            'eventId4', aggregateId1, 3, DateTime.now(), "payload"));
        expect(eventStore.getAllDomainEvents().length, equals(4));
      });

      test('Retrieve all events since timestamp', () {
        // TODO ...

      });

    });
  });

  /// TODO: TO TEST:
  ///  READ:
  ///   - by aggregateId
  ///     - all events
  ///     - snapshot + events afterwards
  ///   - all events since timestamp
  ///     - pushing new events (?)
  ///   - always read in write order (sequence is important!)
  ///   - ad-hoc queries
  ///   - only read committed events
  ///
  ///  WRITE:
  ///   - validate aggregate sequence numbers
  ///   - append (multiple) events (at once)
  ///   - committed events protected against loss
  ///   - append snapshot
  ///   - constant performance as a function of storage size
  ///     -> read/write speed should not increase when lots of events are stored...
  ///
  /// Eventueel een "abstract test-case" schrijven hier, waarmee ik elke implementatie kan testen?
  ///   -
}
