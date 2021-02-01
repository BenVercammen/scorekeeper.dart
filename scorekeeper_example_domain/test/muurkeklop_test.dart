import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.h.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '_test_fixture.dart';

void main() {
  group('Command handling', () {
    TestFixture<MuurkeKlopNDown> fixture;

    setUp(() {
      fixture = TestFixture<MuurkeKlopNDown>(MuurkeKlopNDownCommandHandler(), MuurkeKlopNDownEventHandler());
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

    test('Remove round', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..given(RoundAdded()
            ..aggregateId = _aggregateId
            ..roundIndex = 0
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(1));
        })
        ..when(RemoveRound()
          ..aggregateId = _aggregateId
          ..roundIndex = 0
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(0));
        });
    });

    test('Strike out a participant', () {
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

    test('RoundAdded', () {
      // TODO: is it still useful to check events? We're testing the outcomes in the command handler section anyway...
    });
  });
}
