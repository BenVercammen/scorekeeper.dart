/// An example domain implementation for use within the Scorekeeper application.
library scorekeeper_example_domain;

export 'src/muurkeklop.dart';
export 'src/muurkeklop.f.dart';
export 'src/muurkeklop.h.dart';
export 'src/scorable.dart';
export 'src/scorable.f.dart' hide AggregateDtoFactory;  // TODO: try to merge all in single AggregateDtoFactory...
export 'src/scorable.h.dart';
