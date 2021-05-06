// This is a basic Flutter integration test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_flutter/src/app.dart';
import 'package:scorekeeper_flutter/src/services/service.dart';

void main() {
  // The scorekeeper service to be used within the test
  late ScorekeeperService scorekeeperService;

  // Open the app on the device
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Setup the application
    final _scorekeeper = Scorekeeper(
        eventStore: EventStoreInMemoryImpl(),
        aggregateCache: AggregateCacheInMemoryImpl(),
        domainEventFactory: const DomainEventFactory<Scorable>(
            producerId: 'app_test', applicationVersion: 'v1'))
      ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
      ..registerEventHandler(MuurkeKlopNDownEventHandler());
    scorekeeperService = ScorekeeperService(_scorekeeper);
  });

  testWidgets('Login screen for unauthenticated user',
      (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(ScorableApp(scorekeeperService));
    // Verify that the login screen shows up
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.text('E-mailaddress'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    // Fill in username and password
    // Submit
  });
}
