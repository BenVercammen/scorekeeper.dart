// This file is provided as a convenience for running integration tests via the
// flutter drive command.
//
// Make sure there is at least one device/emulator up and running to test against!
// flutter drive --driver test_driver/driver.dart --target integration_test/app_test.dart

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
