// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/src/scorable.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case Scorable:
        final scorable = aggregate as Scorable;
        return ScorableDto(scorable) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}

class ScorableDto extends AggregateDto {
  ScorableDto(this._scorable) : super(_scorable);

  final Scorable _scorable;

  String get name {
    return _scorable.name;
  }

  List<Participant> get participants {
    return List.of(_scorable.participants, growable: false);
  }
}
