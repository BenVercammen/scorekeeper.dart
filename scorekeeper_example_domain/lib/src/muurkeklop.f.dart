// GENERATED CODE - DO NOT MODIFY BY HAND

import 'dart:core';

import 'package:scorekeeper_domain/src/aggregate.dart';
// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_example_domain/src/muurkeklop.dart';
import 'package:scorekeeper_example_domain/src/scorable.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case MuurkeKlopNDown:
        final muurkeKlopNDown = aggregate as MuurkeKlopNDown;
        return MuurkeKlopNDownDto._(muurkeKlopNDown) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}

class MuurkeKlopNDownDto extends AggregateDto {
  MuurkeKlopNDownDto._(this._muurkeKlopNDown)
      : super(_muurkeKlopNDown.aggregateId);

  final MuurkeKlopNDown _muurkeKlopNDown;

  Map get rounds {
    return _muurkeKlopNDown.rounds;
  }

  String get name {
    return _muurkeKlopNDown.name;
  }

  List<Participant> get participants {
    return List.of(_muurkeKlopNDown.participants, growable: false);
  }

  Set get appliedEvents {
    return _muurkeKlopNDown.appliedEvents;
  }

  AggregateId get aggregateId {
    return _muurkeKlopNDown.aggregateId;
  }

  int get hashCode {
    return _muurkeKlopNDown.hashCode;
  }

  Type get runtimeType {
    return _muurkeKlopNDown.runtimeType;
  }
}
