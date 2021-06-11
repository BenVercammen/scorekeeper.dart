import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_contest/contest.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '_test_fixture.dart';

void main() {
  group('Command handling', () {
    late TestFixture<Contest> fixture;

    setUp(() {
      fixture = TestFixture<Contest>(ContestCommandHandler(), ContestEventHandler());
    });

  });

}
