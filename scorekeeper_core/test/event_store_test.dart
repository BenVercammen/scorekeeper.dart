import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/scorekeeper_test.dart';

/// Tests for the EventStore implementation(s)
///  - EventStoreInMemoryImpl: just keep everything in memory. Okay for testing and a small number of events, but won't scale...
///  - EventStoreLocalStorageImpl: make sure all events are persisted in local storage
///
/// The EventStore just stores local and remote events, no more, no less!
/// The AggregateCache will keep everything in memory (state, snapshots, ...)
/// The EventStore should just be able to read and write/append events.
///
void main() {
  EventStoreTestSuite.runEventStoreTests(EventStoreInMemoryImpl, () => EventStoreInMemoryImpl());
}
