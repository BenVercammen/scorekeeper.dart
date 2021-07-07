// This file is provided as a convenience for running integration tests via the
// flutter drive command.
//
// Make sure there is at least one device/emulator up and running to test against!
// Then run:
// ``flutter drive --driver test_driver/scorekeeper_flutter_it.dart --target test_driver/scorekeeper_driver.dart``

import 'package:flutter_driver/driver_extension.dart';
import 'package:integration_test/integration_test_driver.dart';

import 'package:scorekeeper_flutter/main.dart' as app;

// Future<void> main() => integrationDriver();

void main() {
  // Enable the flutter driver extension
  enableFlutterDriverExtension();

  // Call the main() function of the scorekeeper flutter app.
  // Random filename so we have a "fresh" database on each run...
  final ts = DateTime.now().millisecondsSinceEpoch;
  final randomFilename = 'db_$ts.sqlite';
  app.main(pDbFilename: randomFilename);
}
