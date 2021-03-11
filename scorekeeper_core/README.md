# Scorekeeper
The core library for the scorekeeper application. This package contains the actual application logic,
required for routing events and commands within aggregates.

## Usage

A simple usage example:

```dart
import 'package:scorekeeper_core/scorekeeper.dart';

main() {
  var scorekeeper = new Scorekeeper();
  // TODO ...
}
```


### Cucumber/Ogurets/Gherkin
We do some testing with Gherkin scenario's.
For this purpose, we're using the Ogurets library (https://github.com/dart-ogurets/Ogurets).
To set things up:
 - create or generate the `ogurets_run.dart` file (IntelliJ plugin can do this for us)
 - `dart --enable-asserts test/ogurets_run.dart`




- TODO: https://www.youtube.com/watch?v=dxUnF0F4hdY
- TODO: https://benjiweber.co.uk/blog/2021/01/23/latency-numbers-every-team-should-know/



# Flutter
From time to time, the flutte SDK (installed on the development machine) should be upgraded.
To do so, follow these steps in CLI:
 - `cd %FLUTTER_HOME%`
 - `git reset --hard`
 - `flutter upgrade`

Also re-activate all packages
 - `pub global activate mono_repo`


# Mono Repo
When it's time to upgrade dependencies, this can be done for all packages simultaneously using mono_repo
 - `mono_repo pub upgrade`
 - `mono_repo pub get`