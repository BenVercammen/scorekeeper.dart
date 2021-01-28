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
          ..participant = Participant())
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

    test('RemoveParticipant failed (non-existing participant)', () {
      final _aggregateId = Uuid().v4();
      final participant = Participant()
        ..name = 'Participant 1'
        ..participantId = Uuid().v4();
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

    test('Add round', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..then((scorable) {
          expect(scorable.rounds.length, equals(0));
        })
        ..when(AddRound()
          ..aggregateId = _aggregateId
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(1));
          expect(scorable.rounds[0].roundIndex, equals(0));
          expect(scorable.rounds[0].strikeOutOrder, isEmpty);
        });
    });

    test('StrikeOutParticipant', () {
      final _aggregateId = Uuid().v4();
      final player1 = Participant()
        ..name = 'Player 1'
        ..participantId = Uuid().v4();
      final player2 = Participant()
        ..name = 'Player 2'
        ..participantId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 0
        )
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 1
        )
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player1
        )
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player2
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder, isEmpty);
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
        })
        ..when(StrikeOutParticipant()
          ..aggregateId = _aggregateId
          ..participant = player1
          ..roundIndex = 0
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder.length, equals(1));
          expect(scorable.rounds[0].strikeOutOrder[0], equals(player1));
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
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
          ..participant = Participant())
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
          ..participant = Participant())
        ..then((scorable) {
          expect(scorable.participants.length, equals(0));
        });
    });
  });
}
