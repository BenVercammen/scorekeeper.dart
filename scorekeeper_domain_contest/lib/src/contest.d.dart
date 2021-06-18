// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'package:scorekeeper_domain_contest/src/contest.dart';
import 'dart:core';
import 'package:scorekeeper_domain_contest/src/generated/identifiers.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:scorekeeper_domain/core.dart';

class ContestDto extends AggregateDto {
  ContestDto(this._contest) : super(_contest);

  final Contest _contest;

  String get name {
    return _contest.name;
  }

  List<Participant> get participants {
    return List.of(_contest.participants, growable: false);
  }

  Map<Stage, Set> get stages {
    return _contest.stages;
  }
}

class ContestAggregateId extends AggregateId {
  ContestAggregateId(this.contestId);

  ContestAggregateId._(String id) : contestId = ContestId(uuid: id);

  final ContestId contestId;

  ContestAggregateId.of(this.contestId);

  static ContestAggregateId random() {
    return ContestAggregateId._(const Uuid().v4());
  }

  @override
  Type get type => Contest;
  @override
  String get id => contestId.uuid;
}
