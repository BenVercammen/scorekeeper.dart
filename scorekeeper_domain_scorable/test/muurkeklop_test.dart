import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:scorekeeper_domain_scorable/src/muurkeklop.dart';
import 'package:scorekeeper_domain_scorable/src/muurkeklop.h.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final player1 = Participant(participantId: Uuid().v4(), participantName: 'Player 1');

  final player2 = Participant(participantId: Uuid().v4(), participantName: 'Player 2');

  final domainEventFactory = DomainEventFactory<MuurkeKlopNDown>(producerId: 'MK Test', applicationVersion: 'V1');

  late TestFixture<MuurkeKlopNDown> fixture;

  setUp(() {
    fixture = TestFixture<MuurkeKlopNDown>(MuurkeKlopNDownCommandHandler(), MuurkeKlopNDownEventHandler());
  });

  group('Command handling', () {
    group('Rounds', () {
      test('Add a round', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(0));
          })
          ..when(AddRound()..scorableId = _aggregateId.id)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(1));
            expect(scorable.rounds[0]!.roundIndex, equals(0));
            expect(scorable.rounds[0]!.strikeOutOrder, isEmpty);
          });
      });

      test('Remove a round', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(1));
          })
          ..when(RemoveRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(0));
          });
      });

      test('Start a round', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..when(StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.STARTED));
          });
      });

      test('Start a round without participants', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round cannot start without any players'));
          });
      });

      test('Start a round that has already started', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round already started'));
          });
      });

      test('Start a round that has been paused', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundPaused()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(),
                contains('Round has already been started, please resume instead of restart it'));
          });
      });

      test('Start a round that has been finished', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundFinished()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(
                fixture.lastThrownException.toString(), contains('Round has already been finished, no going back now'));
          });
      });

      test('Pause a round that has already started', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(PauseRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.PAUSED));
          });
      });

      test('Pause a round that has not yet been started', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..when(PauseRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round has not yet been started'));
          });
      });

      test('Pause a round that has already been paused', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundPaused()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(PauseRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round has already been paused'));
          });
      });

      test('Pause a round that has been resumed', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundPaused()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundResumed()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(PauseRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.PAUSED));
          });
      });

      test('Pause a round that has already been finished', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundFinished()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(PauseRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round has already been finished'));
          });
      });

      test('Resume a round that has been paused', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundPaused()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(ResumeRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.STARTED));
          });
      });

      test('Resume a round that is not paused', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..when(ResumeRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round is not paused'));
          });
      });

      test('Finish a round', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(FinishRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.FINISHED));
          });
      });

      test('Finish a round that has not yet started', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..when(FinishRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds[0]!.state, equals(RoundState.FINISHED));
          });
      });
    });

    group('Participant strike-out', () {
      test('Strike out a participant', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player2)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder, isEmpty);
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          })
          ..when(StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder.length, equals(1));
            expect(scorable.rounds[0]!.strikeOutOrder[0], equals(player1));
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          });
      });

      test('Strike out a participant twice in same round', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player2)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantStruckOut()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder.length, equals(1));
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          })
          ..when(StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Player 1 was already struck out in round 1'));
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder.length, equals(1));
            expect(scorable.rounds[0]!.strikeOutOrder[0], equals(player1));
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          });
      });

      test('Undo participant strike out', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player2)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantStruckOut()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder.length, equals(1));
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          })
          ..when(UndoParticipantStrikeOut()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException, isNull);
            expect(scorable.rounds.length, equals(2));
            expect(scorable.rounds[0]!.strikeOutOrder, isEmpty);
            expect(scorable.rounds[1]!.strikeOutOrder, isEmpty);
          });
      });

      /// This scenario points out that we can use Participant VO's interchangeably,
      /// as long as the actual ParticipantId remains the same.
      /// We (currently) want to pass along Participant VO's in our commands so that we
      ///  - can use its properties in command allowance messages
      ///  - can show some basic properties immediately without having to look them up
      test('Strike out modified participant (only matching participantId)', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        final player1b = Participant(participantId: player1.participantId, participantName: 'Player 1B');
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 1)
          ..given(_aggregateId, RoundStarted()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..when(StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..participant = player1b
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException, isNull);
            expect(scorable.rounds[0]!.strikeOutOrder.length, equals(1));
            expect(scorable.rounds[0]!.strikeOutOrder[0], equals(player1));
            expect(scorable.rounds[0]!.strikeOutOrder[0], equals(player1b));
          });
      });

      test('Strike out a participant in a round that has not yet been started', () {
        final _aggregateId = AggregateId.random(MuurkeKlopNDown);
        fixture
          ..given(_aggregateId, ScorableCreated()
            ..name = 'Test'
            ..scorableId = _aggregateId.id)
          ..given(_aggregateId, RoundAdded()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player1)
          ..given(_aggregateId, ParticipantAdded()
            ..scorableId = _aggregateId.id
            ..participant = player2)
          ..when(StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..participant = player1
            ..roundIndex = 0)
          ..then((scorable) {
            expect(fixture.lastThrownException.toString(), contains('Round is not in progress'));
          });
      });
    });
  });

  group('Command allowances', () {
    test('StrikeOutParticipant allowed', () {
      final _aggregateId = AggregateId.random(MuurkeKlopNDown);
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.id)
        ..given(_aggregateId, RoundAdded()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..given(_aggregateId, ParticipantAdded()
          ..scorableId = _aggregateId.id
          ..participant = player1)
        ..given(_aggregateId, RoundStarted()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        // No "when" because we're directly testing the command allowance. Maybe we should not do this?
        ..then((scorable) {
          final command = StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0
            ..participant = player1;
          expect(scorable.isAllowed(command), equals(CommandAllowance(command, true, "Strike out player")));
        });
    });

    test('StrikeOutParticipant when already struck out in the given round', () {
      final _aggregateId = AggregateId.random(MuurkeKlopNDown);
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.id)
        ..given(_aggregateId, RoundAdded()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..given(_aggregateId, ParticipantAdded()
          ..scorableId = _aggregateId.id
          ..participant = player1)
        ..given(_aggregateId, RoundStarted()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..given(_aggregateId, ParticipantStruckOut()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0
          ..participant = player1)
        ..given(_aggregateId, RoundStarted()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        // No "when" because we're directly testing the command allowance. Maybe we should not do this?
        ..then((scorable) {
          final command = StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0
            ..participant = player1;
          expect(scorable.isAllowed(command),
              equals(CommandAllowance(command, false, "Player 1 was already struck out in round 1")));
        });
    });

    test('StrikeOutParticipant for Participant not in Scorable', () {
      final _aggregateId = AggregateId.random(MuurkeKlopNDown);
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.id)
        ..given(_aggregateId, RoundAdded()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..given(_aggregateId, ParticipantAdded()
          ..scorableId = _aggregateId.id
          ..participant = player1)
        ..given(_aggregateId, RoundStarted()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..then((scorable) {
          var command = StrikeOutParticipant()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0
            ..participant = player2;
          expect(scorable.isAllowed(command),
              equals(CommandAllowance(command, false, "Player is not participating in this game")));
        });
    });

    test('StartRound allowed', () {
      final _aggregateId = AggregateId.random(MuurkeKlopNDown);
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.id)
        ..given(_aggregateId, RoundAdded()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..given(_aggregateId, ParticipantAdded()
          ..scorableId = _aggregateId.id
          ..participant = player1)
        ..then((scorable) {
          var command = StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0;
          expect(scorable.isAllowed(command), equals(CommandAllowance(command, true, "Start round")));
        });
    });

    test('StartRound without players', () {
      final _aggregateId = AggregateId.random(MuurkeKlopNDown);
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.id)
        ..given(_aggregateId, RoundAdded()
          ..scorableId = _aggregateId.id
          ..roundIndex = 0)
        ..then((scorable) {
          var command = StartRound()
            ..scorableId = _aggregateId.id
            ..roundIndex = 0;
          expect(scorable.isAllowed(command),
              equals(CommandAllowance(command, false, "Round cannot start without any players")));
        });
    });
  });

  group('Event handling', () {
    test('RoundAdded', () {
      // TODO: is it still useful to check events? We're testing the outcomes in the command handler section anyway...
    });
  });
}
