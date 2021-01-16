
import 'package:scorekeeper_domain/core.dart';

/// Class that will run the tests in a minimal setup so that commands and events are applied to a single Aggregate instance
class TestFixture<T extends Aggregate> {
  final CommandHandler<T> commandHandler;

  final EventHandler<T> eventHandler;

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
    eventHandler.handle(aggregate, DomainEvent.of(EventId.local(), aggregate.aggregateId, event));
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
        eventHandler.handle(aggregate, DomainEvent.of(EventId.local(), aggregate.aggregateId, event));
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
