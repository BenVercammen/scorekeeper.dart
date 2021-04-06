
import 'dart:collection';

import 'package:scorekeeper_domain/core.dart';


/// Cache of Aggregates currently in use by Scorekeeper.
/// Is useful for re-using Aggregate instances
/// and not having to rehydrate them each time they're needed.
abstract class AggregateCache {

  void store(Aggregate aggregate);

  T get<T extends Aggregate>(AggregateId aggregateId);

  void purge(AggregateId aggregateId);

  bool contains(AggregateId aggregateId);

}

/// Simple in memory implementation of AggregateCache.
/// Has no persistence, so needs to be reloaded/hydrated/... on each startup
class AggregateCacheInMemoryImpl implements AggregateCache {

  final Map<AggregateId, Aggregate> _cache = HashMap();

  @override
  T get<T extends Aggregate>(AggregateId aggregateId) {
    return _cache[aggregateId] as T;
  }

  @override
  void purge(AggregateId aggregateId) {
    _cache.remove(aggregateId);
  }

  @override
  void store(Aggregate aggregate) {
    _cache[aggregate.aggregateId] = aggregate;
  }

  @override
  bool contains(AggregateId aggregateId) {
    return _cache.containsKey(aggregateId);
  }

}

/// Exception to be thrown when there's already an Aggregate for the given AggregateId within the system.
class AggregateIdAlreadyExistsException implements Exception {

  final AggregateId aggregateId;

  AggregateIdAlreadyExistsException(this.aggregateId);

}

/// In case a command is invalid
class InvalidCommandException implements Exception {

  final dynamic command;

  final String reason;

  InvalidCommandException(this.command, this.reason);

}

/// In case a command is not supported
class UnsupportedCommandException implements Exception {

  final dynamic command;

  UnsupportedCommandException(this.command);

  @override
  String toString() {
    return 'No command handler registered for $command';
  }

}

/// In case multiple handlers for the same command are registered
class MultipleCommandHandlersException implements Exception {

  final dynamic command;

  MultipleCommandHandlersException(this.command);

  @override
  String toString() {
    return 'Multiple command handlers registered for $command';
  }

}
