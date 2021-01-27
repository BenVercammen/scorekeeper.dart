// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';

import 'scorable.dart';

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

  List get participants {
    return _scorable.participants;
  }
}
