// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandEventHandlerGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';

import 'scorable.dart';

class ScorableCommandHandler implements CommandHandler<Scorable> {
  @override
  bool isConstructorCommand(dynamic command) {
    return command is CreateScorable;
  }

  @override
  Scorable handleConstructorCommand(dynamic command) {
    return Scorable.command(command as CreateScorable);
  }

  @override
  void handle(Scorable scorable, dynamic command) {
    switch (command.runtimeType) {
      case AddParticipant:
        scorable.addParticipant(command as AddParticipant);
        return;
      case RemoveParticipant:
        scorable.removeParticipant(command as RemoveParticipant);
        return;
      default:
        throw Exception('Unsupported command ${command.runtimeType}.');
    }
  }

  @override
  Scorable newInstance(AggregateId aggregateId) {
    return Scorable.aggregateId(aggregateId);
  }

  @override
  bool handles(dynamic command) {
    switch (command.runtimeType) {
      case CreateScorable:
      case AddParticipant:
      case RemoveParticipant:
        return true;
      default:
        return false;
    }
  }
}

class ScorableEventHandler implements EventHandler<Scorable> {
  @override
  void handle(Scorable scorable, DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ScorableCreated:
        scorable.handleScorableCreated(event.payload as ScorableCreated);
        return;
      case ParticipantAdded:
        scorable.handleParticipantAdded(event.payload as ParticipantAdded);
        return;
      case ParticipantRemoved:
        scorable.handleParticipantRemoved(event.payload as ParticipantRemoved);
        return;
      default:
        throw Exception('Unsupported event ${event.payload.runtimeType}.');
    }
  }

  @override
  bool forType(Type type) {
    return type == Scorable;
  }

  @override
  Scorable newInstance(AggregateId aggregateId) {
    return Scorable.aggregateId(aggregateId);
  }

  @override
  bool handles(DomainEvent event) {
    switch (event.payload.runtimeType) {
      case ScorableCreated:
      case ParticipantAdded:
      case ParticipantRemoved:
        return true;
      default:
        return false;
    }
  }
}


/// TODO: generate this class!!!
abstract class AggregateDtoFactory {

  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case Scorable:
        final scorable = aggregate as Scorable;
        return ScorableDto._(scorable) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }

}

/// TODO: generate this class!!!
class ScorableDto extends AggregateDto {

  final Scorable _scorable;

  /// Protected constructor so outside packages cannot instantiate DTO's,
  /// this will always need to go through the AggregateDtoFactory
  ScorableDto._(this._scorable) : super(_scorable.aggregateId);

  String get name => _scorable.name;

  List<Participant> get participants => List.from(_scorable.participants);

  @override
  String toString() {
    return _scorable.toString();
  }

}

