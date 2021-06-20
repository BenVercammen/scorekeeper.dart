
import 'package:scorekeeper_core/scorekeeper_test_util.dart';

import 'event_store_moor_test.dart';

/// In this test we'll validate our EventStore implementation.
void main() {

  EventStoreTestSuite().runEventStoreTests(TestEventStoreMoorImpl, () => TestEventStoreMoorImpl());

}
