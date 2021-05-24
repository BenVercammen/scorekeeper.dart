import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class TracingLogger extends Logger {
  final Map<Level, List<String>> loggedMessages = HashMap();

  @override
  void log(Level level, message, [error, StackTrace? stackTrace]) {
    super.log(level, message, error, stackTrace);
    loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
    loggedMessages[level]?.add(message.toString());
  }
}

/// Abstract class containing the test suite for all EventStore implementations.
/// This way we can easily reuse the default test set across multiple implementations.
abstract class EventStoreTestSuite {
  static void runEventStoreTests(
      Type eventStoreType, Function() constructorCallback) {
    final DomainEventFactory domainEventFactory = DomainEventFactory(
        producerId: 'prodId', applicationVersion: 'appVersion');
    final EventStore eventStore = constructorCallback();

    final aggregateId1 = AggregateId.random();
    final aggregateId2 = AggregateId.random();
    final aggregateId3 = AggregateId.random();
    final eventId1 = Uuid().v4();
    final eventId2 = Uuid().v4();
    final eventId3 = Uuid().v4();
    final eventId4 = Uuid().v4();
    final ts1 = DateTime.now().subtract(Duration(minutes: 5));
    final ts2 = DateTime.now().subtract(Duration(minutes: 4));
    final ts3 = DateTime.now().subtract(Duration(minutes: 3));
    final ts4 = DateTime.now().subtract(Duration(minutes: 2));

    setUp(() async {
      await eventStore.clear();
      // Register Aggregates so the events are being stored
      await eventStore.registerAggregateId(aggregateId1);
      await eventStore.registerAggregateId(aggregateId2);
      await eventStore.registerAggregateId(aggregateId3);
    });

    /// For InMemoryImpl it's simple...
    group(eventStoreType, () {
      group('READ', () {
        test('Event should be stored and retrievable', () async {
          var domainEvent1 = domainEventFactory.remote(
              eventId1, aggregateId1, 0, DateTime.now(), 'payload');
          await eventStore.storeDomainEvent(domainEvent1);
          expect(await eventStore.getDomainEvents().toList(),
              contains(domainEvent1));
        });

        test('Retrieve all stored events by aggregateId', () async {
          // Given...
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId1, aggregateId1, 0, DateTime.now(), 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId2, aggregateId2, 0, DateTime.now(), 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId3, aggregateId1, 1, DateTime.now(), 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId4, aggregateId2, 1, DateTime.now(), 'payload'));
          // When
          final domainEvents = await eventStore
              .getDomainEvents(aggregateId: aggregateId1)
              .toSet();
          // Then
          expect(domainEvents.length, equals(2));
        });

        test('Retrieve all events since timestamp', () async {
          // Given...
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId1, aggregateId1, 0, ts1, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId2, aggregateId2, 0, ts2, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId3, aggregateId1, 1, ts3, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId4, aggregateId2, 1, ts4, 'payload'));
          // When
          final domainEvents =
              await eventStore.getDomainEvents(timestamp: ts2).toSet();
          // Then the 3 events since TS2 should show up
          expect(domainEvents.length, equals(3));
        });

        test('Retrieve all aggregate events since timestamp', () async {
          // Given...
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId1, aggregateId1, 0, ts1, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId2, aggregateId2, 0, ts2, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId3, aggregateId1, 1, ts3, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId4, aggregateId2, 1, ts4, 'payload'));
          // When
          final domainEvents = await eventStore
              .getDomainEvents(aggregateId: aggregateId1, timestamp: ts2)
              .toSet();
          // Then the new event since TS2 should show up
          expect(domainEvents.length, equals(1));
        });

        test('Retrieving events since sequence requires aggregateId', () {
          // TODO: calling getDomainEvents(sequence without aggregateId) ==> error
        });

        /// NOTE: since we require a correct +1 on sequences, this became kind of a moot point to test...
        test('Retrieve all aggregate events in sequence order', () async {
          // Given...
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId1, aggregateId1, 0, ts2, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId2, aggregateId1, 1, ts1, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId3, aggregateId1, 2, ts4, 'payload'));
          await eventStore.storeDomainEvent(domainEventFactory.remote(
              eventId4, aggregateId1, 3, ts3, 'payload'));
          // When
          final domainEvents = await eventStore.getDomainEvents().toList();
          // Then events should be sorted by sequence
          var eventIds = domainEvents.map((event) => event.sequence);
          expect(eventIds, equals([0, 1, 2, 3]));
        });

        /// TODO: read as stream!? event store should return a stream of events
        /// mainly for performance shit (loading all events in memory is not wise to do...
      });

      group('WRITE', () {
        group('Validate sequence number', () {
          /// Events should be written in sequence order
          /// It is not allowed to write an already used sequence,
          /// or to skip a sequence number.
          test('Sequence number should be positive', () async {
            try {
              await eventStore.storeDomainEvent(
                  domainEventFactory.local(aggregateId1, -1, 'payload'));
              fail('Expected InvalidEventException');
            } on InvalidEventException catch (e) {
              expect(e.toString(), contains('Invalid sequence'));
            }
          });

          test('AggregateId should be known/registered if sequence > 0',
              () async {
            try {
              await eventStore.storeDomainEvent(domainEventFactory.local(
                  AggregateId.of('unknownaggregateid'), 1, 'payload'));
              fail('Expected InvalidEventException');
            } on InvalidEventException catch (e) {
              expect(e.toString(), contains('AggregateId not registered'));
            }
          });

          test('AggregateId should be registered', () async {
            try {
              await eventStore.storeDomainEvent(domainEventFactory.local(
                  AggregateId.of('unknownaggregateid'), 0, 'payload'));
              fail('Expected InvalidEventException');
            } on InvalidEventException catch (e) {
              expect(e.toString(), contains('AggregateId not registered'));
            }
          });

          test('EventId should be unique', () async {
            // First event
            await eventStore.storeDomainEvent(domainEventFactory.remote(
                eventId1, aggregateId1, 0, DateTime.now(), 'payload'));
            try {
              // Second event with same eventId, all other parameters are different, should fail
              await eventStore.storeDomainEvent(domainEventFactory.remote(
                  eventId1, aggregateId2, 1, DateTime.now(), 'payload2'));
              fail('Expected InvalidEventException');
            } on InvalidEventException catch (e) {
              expect(
                  e.toString(),
                  contains(
                      'Non-identical event with the same ID already stored in EventStore'));
            }
          });

          /// In case we receive the same event twice, we just silently ignore it.
          /// Equals means the same EventId, AggregateId and sequence.
          test('Duplicate events should throw exception', () async {
            // First event
            await eventStore.storeDomainEvent(domainEventFactory.remote(
                eventId1, aggregateId1, 0, DateTime.now(), 'payload'));
            try {
              // Second event with same EventId, AggregateId and sequence, should fail
              await eventStore.storeDomainEvent(domainEventFactory.remote(
                  eventId1, aggregateId1, 0, DateTime.now(), 'payload'));
              fail('Expected InvalidEventException');
            } on InvalidEventException catch (e) {
              expect(e.toString(), contains('Event already stored'));
            }
          });
        });
      });
    });

    /// TODO: TO TEST:
    ///  READ:
    ///   - by aggregateId
    ///     x all events
    ///     - snapshot + events afterwards
    ///   x all events since timestamp
    ///     - pushing new events (?)
    ///   x always read in write order (sequence is important!)
    ///   ? ad-hoc queries
    ///   ? only read committed events
    ///
    ///  WRITE:
    ///   x validate aggregate sequence numbers
    ///   x append (multiple) events (at once)
    ///   ? committed events protected against loss
    ///   - append snapshot
    ///   ? constant performance as a function of storage size
    ///     -> read/write speed should not increase when lots of events are stored...
    ///
    /// Eventueel een "abstract test-case" schrijven hier, waarmee ik elke implementatie kan testen?
    ///   -
    ///
    /// TODO: SNAPSHOTS:
    ///   https://domaincentric.net/blog/event-sourcing-snapshotting
    ///   https://docs.axoniq.io/reference-guide/axon-framework/tuning/event-snapshots
    ///   voorlopig nog even mee wachten? Is optimalisatie...
  }
}
