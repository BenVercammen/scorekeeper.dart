import 'package:scorekeeper_domain/core.dart';

class AggregateDtoFactory {
  static R create<R extends AggregateDto>(Aggregate aggregate) {
    switch (aggregate.runtimeType) {
      default:
        throw Exception('Cannot create $R for ${aggregate.runtimeType}');
    }
  }
}
