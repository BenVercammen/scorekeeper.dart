// This is a basic Flutter integration test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:scorekeeper_flutter/main.dart' as app;
import 'package:test/test.dart';

void main() {
  enableFlutterDriverExtension();
  app.main();
}

void _testMain() {

  FlutterDriver driver;

  // Connect to the Flutter driver before running any tests.
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  // Close the connection to the driver after the tests have completed.
  tearDownAll(() async {
    if (driver != null) {
      driver.close();
    }
  });

  test('Show add scorable button', () async {
    expect(await driver.getWidgetDiagnostics(find.byValueKey('Add')), 'Add scorable');

  });
}
