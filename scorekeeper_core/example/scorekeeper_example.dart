import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:uuid/uuid.dart';

void main() {

  // Create an instance
  final scorekeeper = Scorekeeper(EventManagerInMemoryImpl(), null, AggregateCacheImpl())
    // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(ScorableCommandHandler())
    ..registerEventHandler(ScorableEventHandler());

  // Handle a command
  final command = CreateScorable()
    ..aggregateId = Uuid().v4()
    ..name = 'Test Scorable 1';
  scorekeeper.handleCommand(command);

}

