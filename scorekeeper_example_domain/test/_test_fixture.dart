
import 'dart:collection';

import 'package:scorekeeper_domain/core.dart';

/// Class that will run the tests in a minimal setup so that commands and events are applied to a single Aggregate instance
///
/// TODO: currently we still need to generate the handler class every time we change our code...
///       it would be better if this TestFixture could dynamically determine the right handlers...
///       that would require some sort of "DynamicReflectionEventHandlerForAggregate" typed instance
///       let's see if we can dig up our old reflection code somewhere...
class TestFixture<T extends Aggregate> {
  late final CommandHandler<T> commandHandler;

  late final EventHandler<T> eventHandler;

  late final Map<Aggregate, int> eventSequenceMap = HashMap();

  T? aggregate;

  Exception? lastThrownException;

  TestFixture(this.commandHandler, this.eventHandler);

  TestFixture given(dynamic event) {
    if (event.aggregateId == null) {
        throw Exception('AggregateId was not set on event ${event.runtimeType}');
    }
    // Ignore events for different aggregateId's...
    if (aggregate != null && event.aggregateId != aggregate?.aggregateId.id) {
      return this;
    }
    final aggregateId = AggregateId.of(event.aggregateId.toString());
    aggregate ??= eventHandler.newInstance(aggregateId);
    var sequence = eventSequenceMap[aggregate] ?? 0;
    eventSequenceMap[aggregate!] = sequence++;
    eventHandler.handle(aggregate!, DomainEvent.of(DomainEventId.local(sequence), aggregate!.aggregateId, event));
    return this;
  }

  TestFixture when(dynamic command) {
    try {
      if (commandHandler.isConstructorCommand(command)) {
        aggregate = commandHandler.handleConstructorCommand(command);
      } else {
        commandHandler.handle(aggregate!, command);
      }
      for (var event in aggregate!.appliedEvents) {
        var sequence = eventSequenceMap[aggregate] ?? 0;
        eventSequenceMap[aggregate!] = sequence++;
        eventHandler.handle(aggregate!, DomainEvent.of(DomainEventId.local(sequence), aggregate!.aggregateId, event));
      }
      lastThrownException = null;
    } on Exception catch (exception) {
      lastThrownException = exception;
    }
    return this;
  }

  TestFixture then(Function(T aggregate) callback) {
    callback(aggregate!);
    return this;
  }
}
