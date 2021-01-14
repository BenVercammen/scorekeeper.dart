import 'package:example_domain/example.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '_test_fixture.dart';

void main() {
  group('Command handling', () {
    TestFixture<Scorable> fixture;

    setUp(() {
      fixture = TestFixture<Scorable>(ScorableCommandHandler(), ScorableEventHandler());
    });

    test('CreateScorable success', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..when(CreateScorable()
          ..name = 'Test 1'
          ..aggregateId = _aggregateId)
        ..then((scorable) {
          expect(scorable.aggregateId, equals(AggregateId.of(_aggregateId)));
          expect(scorable.name, equals('Test 1'));
        });
    });

    test('AddParticipant succes', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..when(AddParticipant()
          ..aggregateId = _aggregateId
          ..participant = Participant())
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });
  });

  group('Event handling', () {
    TestFixture<Scorable> fixture;

    setUp(() {
      fixture = TestFixture<Scorable>(ScorableCommandHandler(), ScorableEventHandler());
    });

    test('ScorableCreated', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..then((scorable) {
          expect(scorable.name, equals('Test'));
          expect(scorable.aggregateId.id, equals(_aggregateId));
          expect(scorable.participants.length, equals(0));
        });
    });


    test('ParticipantAdded', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..given(ParticipantAdded()
            ..aggregateId = _aggregateId
            ..participant = Participant()
        )
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

  });
}
