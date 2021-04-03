// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/src/scorable.dart';

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
