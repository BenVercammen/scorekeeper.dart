import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:scorekeeper_domain/core.dart' as c;

/// Generated DTO factory for instantiating AggregateDto's based on actual Aggregate classes.
/// These AggregateDto's are used as value objects for consuming classes, as we don't want them
/// to have access to the annotated handler methods.
class AggregateDtoFactory implements c.AggregateDtoFactory {
  @override
  R create<R extends c.AggregateDto>(c.Aggregate aggregate) {
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
