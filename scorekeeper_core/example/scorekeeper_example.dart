import 'package:example_domain/example.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:uuid/uuid.dart';

void main() {

  // Create an instance
  var scorekeeper = Scorekeeper(EventManagerInMemoryImpl(), null, AggregateCacheImpl());
  // Register the command and event handlers for the relevant domain
  scorekeeper.registerCommandHandler(ScorableCommandHandler());
  scorekeeper.registerEventHandler(ScorableEventHandler());

  // Handle a command
  CreateScorable command = CreateScorable();
  command.aggregateId = Uuid().v4();
  command.name = 'Test Scorable 1';
  scorekeeper.handleCommand(command);


}

