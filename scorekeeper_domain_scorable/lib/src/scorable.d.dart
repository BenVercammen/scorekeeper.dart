// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'package:scorekeeper_domain_scorable/src/scorable.dart';
import 'package:scorekeeper_domain_scorable/src/generated/events.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:scorekeeper_domain/core.dart';

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
