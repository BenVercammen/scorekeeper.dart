import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_contest/contest.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      case Contest:
        final contest = aggregate as Contest;
        return ContestDto(contest) as R;
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}
