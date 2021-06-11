import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Scorable Value Objects', () {
    group('Participant', () {

      /// It is important that Value Objects that contain references to other aggregates/entities
      /// are only checking against the referenced entity ID, and not any of the other properties.
      /// This way we can just check use the default contains methods etc when checking if a Participant VO is present or not.
      test('Participant should equal on ParticipantId only', () {
        final player1 = Participant(Uuid().v4(), 'Player 1');
        final player1b = Participant(player1.participantId, 'Player 2');
        final player2 = Participant(Uuid().v4(), 'Player 2');
        expect(player1, equals(player1b));
        expect(player1, isNot(equals(player2)));
        expect(player1b, isNot(equals(player2)));
      });
    });
  });
}
