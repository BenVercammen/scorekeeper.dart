// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AggregateDtoFactoryGenerator
// **************************************************************************

import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.dart';
import 'package:scorekeeper_example_domain/src/scorable.f.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case MuurkeKlopNDown:
        final muurkeKlopNDown = aggregate as MuurkeKlopNDown;
        return MuurkeKlopNDownDto(muurkeKlopNDown) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}

class MuurkeKlopNDownDto extends ScorableDto {
  MuurkeKlopNDownDto(this._muurkeKlopNDown) : super(_muurkeKlopNDown);

  final MuurkeKlopNDown _muurkeKlopNDown;

  Map get rounds {
    return _muurkeKlopNDown.rounds;
  }
}
