import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
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
          ..participant = Participant(null, null))
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

    test('RemoveParticipant failed (non-existing participant)', () {
      final _aggregateId = Uuid().v4();
      final participant = Participant(Uuid().v4(), 'Participant 1');
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..when(RemoveParticipant()
          ..aggregateId = _aggregateId
          ..participant = participant)
        ..then((scorable) {
          expect(fixture.lastThrownException.toString(), contains('Participant not on Scorable'));
          expect(scorable.participants.length, equals(0));
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
          ..participant = Participant(null, null))
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

    test('ParticipantRemoved', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..given(ParticipantRemoved()
          ..aggregateId = _aggregateId
          ..participant = Participant(null, null))
        ..then((scorable) {
          expect(scorable.participants.length, equals(0));
        });
    });
  });
}
