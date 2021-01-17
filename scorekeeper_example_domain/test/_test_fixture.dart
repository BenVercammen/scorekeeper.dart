
import 'dart:collection';

import 'package:scorekeeper_domain/core.dart';
import 'package:uuid/uuid.dart';

/// Class that will run the tests in a minimal setup so that commands and events are applied to a single Aggregate instance
class TestFixture<T extends Aggregate> {
  final CommandHandler<T> commandHandler;

  final EventHandler<T> eventHandler;

  final Map<Aggregate, int> eventSequenceMap = HashMap();

  T aggregate;

  Exception lastThrownException;

  TestFixture(this.commandHandler, this.eventHandler);

  TestFixture given(dynamic event) {
    if (event.aggregateId == null) {
        throw Exception('AggregateId was not set on event ${event.runtimeType}');
    }
    // Ignore events for different aggregateId's...
    if (aggregate != null && event.aggregateId != aggregate.aggregateId.id) {
      return this;
    }
    final aggregateId = AggregateId.of(event.aggregateId.toString());
    aggregate ??= eventHandler.newInstance(aggregateId);
    final sequence = eventSequenceMap[aggregate]++;
    eventHandler.handle(aggregate, DomainEvent.of(DomainEventId.local(Uuid().v4(), sequence), aggregate.aggregateId, event));
    return this;
  }

  TestFixture when(dynamic command) {
    try {
      if (commandHandler.isConstructorCommand(command)) {
        aggregate = commandHandler.handleConstructorCommand(command);
      } else {
        commandHandler.handle(aggregate, command);
      }
      for (var event in aggregate.appliedEvents) {
        final sequence = eventSequenceMap[aggregate]++;
        eventHandler.handle(aggregate, DomainEvent.of(DomainEventId.local(Uuid().v4(), sequence), aggregate.aggregateId, event));
      }
      lastThrownException = null;
    } on Exception catch (exception) {
      lastThrownException = exception;
    }
    return this;
  }

  TestFixture then(Function(T aggregate) callback) {
    callback(aggregate);
    return this;
  }
}
