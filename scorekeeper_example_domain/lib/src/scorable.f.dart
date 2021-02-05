// GENERATED CODE - DO NOT MODIFY BY HAND

import 'dart:core';

import 'package:scorekeeper_domain/src/aggregate.dart';
// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_example_domain/src/scorable.dart';

class AggregateDtoFactory {
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

class ScorableDto extends AggregateDto {
  ScorableDto._(this._scorable) : super(_scorable.aggregateId);

  final Scorable _scorable;

  String get name {
    return _scorable.name;
  }

  List<Participant> get participants {
    return List.of(_scorable.participants, growable: false);
  }

  Set get appliedEvents {
    return _scorable.appliedEvents;
  }

  AggregateId get aggregateId {
    return _scorable.aggregateId;
  }

  int get hashCode {
    return _scorable.hashCode;
  }

  Type get runtimeType {
    return _scorable.runtimeType;
  }
}
