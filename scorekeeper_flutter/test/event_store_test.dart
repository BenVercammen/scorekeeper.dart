

import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_eventstore_moor/event_store_moor.dart';

/// In this test we'll validate our various EventStore implementations.
void main() {

  EventStoreTestSuite.runEventStoreTests(EventStoreMoorImpl, () => EventStoreMoorImpl());

}