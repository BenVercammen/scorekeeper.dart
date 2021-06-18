// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'package:scorekeeper_domain_scorable/src/scorable.dart';
import 'package:scorekeeper_domain_scorable/src/generated/events.pb.dart';
import 'package:scorekeeper_domain_scorable/src/generated/identifiers.pb.dart';
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

class ScorableAggregateId extends AggregateId {
  ScorableAggregateId(this.scorableId);

  ScorableAggregateId._(String id) : scorableId = ScorableId(uuid: id);

  final ScorableId scorableId;

  static ScorableAggregateId of(String id) {
    return ScorableAggregateId._(id);
  }

  static ScorableAggregateId random() {
    return ScorableAggregateId._(const Uuid().v4());
  }

  @override
  Type get type => Scorable;
  @override
  String get id => scorableId.uuid;
}
