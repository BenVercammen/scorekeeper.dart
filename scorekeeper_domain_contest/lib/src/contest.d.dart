// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'package:scorekeeper_domain_contest/src/contest.dart';
import 'dart:core';
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
