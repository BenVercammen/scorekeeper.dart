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

  group('Event serialization', () {

    final serializer = ContestSerializer();
    final deserializer = ContestDeserializer();

    /// Serialization testen...
    /// Eigenlijk hebben we 2 soorten events he:
    ///   - "puur/zuiver domain event", zonder metadata, geen ID, niets...
    ///     -> dat is 't geen we in onze event handlers willen krijgen
    ///   - "wrapped domain event", mét metadata, dat we nodig hebben voor Scorekeeper eventstore & message handling/routing stuff...
    ///   => TODO: beetje probleem da'k er nu mee heb, is dat ik die metadata niet per se wil exposen in domain, ma bon...
    ///
    test('ContestCreated', () {
      final _aggregateId = Uuid().v4();
      final event = ContestCreated(
        // TODO: metadata: EventMetadata(),  // Gaan we da nu wel of nie in da event steken?
        contestName: 'Test',
        contestId: ContestId(uuid: _aggregateId));
      final serialized = serializer.serialize(event);
      final deserialized = deserializer.deserialize('ContestCreated', serialized);
      expect(deserialized, equals(event));
    });
  });



}
