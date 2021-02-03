import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.dart';
import 'package:scorekeeper_example_domain/src/muurkeklop.h.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '_test_fixture.dart';

void main() {

  final player1 = Participant(Uuid().v4(), 'Player 1');

  final player2 = Participant(Uuid().v4(), 'Player 2');

  TestFixture<MuurkeKlopNDown> fixture;

  setUp(() {
    fixture = TestFixture<MuurkeKlopNDown>(MuurkeKlopNDownCommandHandler(), MuurkeKlopNDownEventHandler());
  });

  group('Command handling', () {

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
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId
        )
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

    test('Strike out a participant twice in same round', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId
        )
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 0
        )
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 1)
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player1
        )
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player2
        )
        ..given(ParticipantStrikedOut()
            ..aggregateId = _aggregateId
            ..participant = player1
            ..roundIndex = 0
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder.length, equals(1));
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
        })
        ..when(StrikeOutParticipant()
          ..aggregateId = _aggregateId
          ..participant = player1
          ..roundIndex = 0
        )
        ..then((scorable) {
          expect(fixture.lastThrownException.toString(), contains('Player 1 already striked out in round 1'));
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder.length, equals(1));
          expect(scorable.rounds[0].strikeOutOrder[0], equals(player1));
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
        });
    });

    test('Undo participant strike out', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId
        )
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 0
        )
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 1)
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player1
        )
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player2
        )
        ..given(ParticipantStrikedOut()
            ..aggregateId = _aggregateId
            ..participant = player1
            ..roundIndex = 0
        )
        ..then((scorable) {
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder.length, equals(1));
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
        })
        ..when(UndoParticipantStrikeOut()
          ..aggregateId = _aggregateId
          ..participant = player1
          ..roundIndex = 0
        )
        ..then((scorable) {
          expect(fixture.lastThrownException, isNull);
          expect(scorable.rounds.length, equals(2));
          expect(scorable.rounds[0].strikeOutOrder, isEmpty);
          expect(scorable.rounds[1].strikeOutOrder, isEmpty);
        });
    });


  });

  group('Command allowances', () {
    test('PlayerStrikedOut when already striked out in the given round', () {
      final _aggregateId = Uuid().v4();
      fixture
        ..given(ScorableCreated()
          ..name = 'Test'
          ..aggregateId = _aggregateId)
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 0)
        ..given(RoundAdded()
          ..aggregateId = _aggregateId
          ..roundIndex = 1)
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player1)
        ..given(ParticipantAdded()
          ..aggregateId = _aggregateId
          ..participant = player2)
        ..given(ParticipantStrikedOut()
            ..aggregateId = _aggregateId
            ..roundIndex = 0
            ..participant = player1)
        ..then((scorable) {
          var command = StrikeOutParticipant()
            ..roundIndex = 0
            ..participant = player1;
          expect(scorable.isAllowed(command), equals(CommandAllowance(command, false, "Player was already striked out in this round")));
        });
    });
  });

  group('Event handling', () {

    test('RoundAdded', () {
      // TODO: is it still useful to check events? We're testing the outcomes in the command handler section anyway...
    });
  });
}
