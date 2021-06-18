import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case MuurkeKlopNDown:
        final muurkeKlopNDown = aggregate as MuurkeKlopNDown;
        return MuurkeKlopNDownDto(muurkeKlopNDown) as R;
      case Scorable:
        final scorable = aggregate as Scorable;
        return ScorableDto(scorable) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}

class AggregateIdFactory {
  static R of<R extends AggregateId>(String id, String type) {
    switch (type) {
      case 'MuurkeKlopNDown':
        return MuurkeKlopNDownAggregateId.of(id) as R;
      case 'Scorable':
        return ScorableAggregateId.of(id) as R;
      default:
        throw Exception('Cannot create $R of type "$type" with id "$id"');
    }
  }
}
