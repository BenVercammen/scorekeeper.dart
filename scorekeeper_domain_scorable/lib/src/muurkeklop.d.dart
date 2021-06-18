// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'dart:core';
import 'package:scorekeeper_domain_scorable/src/muurkeklop.dart';
import 'package:scorekeeper_domain_scorable/src/generated/identifiers.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:scorekeeper_domain_scorable/src/scorable.d.dart';

class MuurkeKlopNDownDto extends ScorableDto {
  MuurkeKlopNDownDto(this._muurkeKlopNDown) : super(_muurkeKlopNDown);

  final MuurkeKlopNDown _muurkeKlopNDown;

  Map<int, MuurkeKlopNDownRound> get rounds {
    return _muurkeKlopNDown.rounds;
  }
}

class MuurkeKlopNDownAggregateId extends ScorableAggregateId {
  MuurkeKlopNDownAggregateId(this.scorableId) : super(scorableId);

  final ScorableId scorableId;

  static MuurkeKlopNDownAggregateId of(String id) {
    return MuurkeKlopNDownAggregateId(ScorableId(uuid: id));
  }

  static MuurkeKlopNDownAggregateId random() {
    return MuurkeKlopNDownAggregateId(ScorableId(uuid: const Uuid().v4()));
  }

  @override
  Type get type => MuurkeKlopNDown;
  @override
  String get id => scorableId.uuid;
}
