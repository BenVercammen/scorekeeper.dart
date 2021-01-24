import 'package:ogurets/ogurets.dart';

import 'event_test.dart' as event_test;
import 'features/step_definitions.dart' as step_definitions;

// THIS FILE IS GENERATED - it will be overwritten on each run.
// If you wish to use one, please just make a copy and use that.
// Your friendly Ogurets team - Irina Southwell & Richard Vowles
//  (and we hope supporting cast)
// if you have an issue please raise it on
// https://github.com/dart-ogurets/Ogurets (for core)
// https://github.com/dart-ogurets/OguretsFlutter (for ogurets_flutter)
// https://github.com/dart-ogurets/OguretsIntellij (for the Jetbrains IntelliJ plugin)
void main(args) async {
  var def = new OguretsOpts()
    ..feature('test/features/event_synchronization.feature')
    ..debug()
    ..step(step_definitions.StepDefinitions)..step(step_definitions.ConstructorEvent)..step(
        step_definitions.RegularEvent)..step(event_test.ScorableCreatedWithEquals)
  ;

  await def.run();
}