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
