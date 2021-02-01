// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';

import 'muurkeklop.dart';

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
}
