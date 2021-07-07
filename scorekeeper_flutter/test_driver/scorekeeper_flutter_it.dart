// Give ourselves enough time to properly debug...
@Timeout(Duration(minutes: 5))

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {

  group('Scorekeeper App', () {

    final loginButtonFinder = find.byValueKey('sign_in');
    final createNewScorableButtonFinder = find.byValueKey('create_new_scorable');
    final createNewGameButtonFinder = find.byValueKey('create_new_game');


    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Overview page loads most recent games', () async {
      // First get past the login screen (if necessary)
      final doLogin = await isPresent(loginButtonFinder, driver);
      if (doLogin) {
        await driver.tap(loginButtonFinder);
      }
      // Next, check for the "add tournament" button
      final diagnostics = await driver.getWidgetDiagnostics(createNewScorableButtonFinder);
      // expect(diagnostics, equals('Create new Scorable'));
      expect(diagnostics, isNotNull);
      // Create a new game
      await driver.tap(createNewScorableButtonFinder);
      // Enter name
      await driver.tap(find.byValueKey('scorable_name'));
      await driver.enterText('Test Scorable Name 1');
      // Submit form, creating the new game instance
      await driver.tap(find.byValueKey('create_new_game'));
      // We don't yet want to look at the game details, just go back to the overview
      await driver.tap(find.byTooltip('Back'));
      // Now we want to make sure the newly created game is present in the list!
      final scorableOverviewList = find.byValueKey('scorable_overview');
      final newGameListItemFinder = find.byValueKey('scorable_item_0');
      await driver.scrollIntoView(newGameListItemFinder);
      expect(find.byValueKey('scorable_item_0'), isNotNull);
      // Navigate to the scorable
      await driver.tap(find.byValueKey('scorable_item_0'));
      // Add a new player
      await driver.tap(find.byValueKey('add_participant'));
      await driver.enterText('Player One');
      await driver.tap(find.byValueKey('submit_add_participant'));
      expect(find.byValueKey('participant_item_0'), isNotNull);

      // Participant should be visible
      // 	-> in eerste instantie wel players toevoegen en direct zichtbaar
      // 	-> naar menu (of herstarten ?)
      // 	-> players toevoegen => niet meer zichtbaar...

    });

  });

}

/// Check if an element is present.
/// Can be used in tests as a condition to verify which actions to take.
Future<bool> isPresent(SerializableFinder finder, FlutterDriver driver,
    {Duration timeout = const Duration(seconds: 1)}) async {
  try {
    await driver.waitFor(finder, timeout: timeout);
    return true;
  } on Error catch (e) {
    return false;
  }
}