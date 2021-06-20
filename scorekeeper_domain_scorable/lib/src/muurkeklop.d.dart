// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoGenerator
// **************************************************************************

import 'dart:core';
import 'package:scorekeeper_domain_scorable/src/muurkeklop.dart';
import 'package:uuid/uuid.dart';
import 'package:scorekeeper_domain_scorable/src/scorable.d.dart';

class MuurkeKlopNDownDto extends ScorableDto {
  MuurkeKlopNDownDto(this._muurkeKlopNDown) : super(_muurkeKlopNDown);

  final MuurkeKlopNDown _muurkeKlopNDown;

  Map<int, MuurkeKlopNDownRound> get rounds {
    return _muurkeKlopNDown.rounds;
  }
}
