
import 'aggregate.dart';
import 'event.dart';

/// Interface to be implemented by the generated domain command handler
abstract class CommandHandler<T extends Aggregate, A extends AggregateId> {

  /// Check if the given command should call a constructor
  bool isConstructorCommand(dynamic command);

  /// Handle constructor command
  /// This will actually instantiate an Aggregate
  T handleConstructorCommand(dynamic command);

  /// Create a new empty instance
  T newInstance(A aggregateId);

  /// Handle regular (non-constructor) commands
  void handle(T aggregate, dynamic command);

  /// Returns whether or not this CommandHandler can handle the given command
  bool handles(dynamic command);

}


/// Interface to be implemented by the generated domain event handler
abstract class EventHandler<T extends Aggregate, A extends AggregateId> {

  void handle(T aggregate, DomainEvent<T, A> event);

  /// Returns whether or not this EventHandler can handle the given DomainEvent
  /// TODO: eigenlijk toch weer niet gebruikt?
  bool handles(DomainEvent<T, A> event);

  bool forType(Type type);

  /// Create a new empty instance
  T newInstance(A aggregateId);

}
