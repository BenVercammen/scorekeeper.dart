import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {

  group('Command handling', () {
    late TestFixture<Scorable, ScorableAggregateId> fixture;

    setUp(() {
      fixture = TestFixture<Scorable, ScorableAggregateId>(ScorableCommandHandler(), ScorableEventHandler());
    });

    test('CreateScorable success', () {
      final _aggregateId = ScorableAggregateId.random();
      fixture
        ..when(CreateScorable()
          ..name = 'Test 1'
          ..scorableId = _aggregateId.scorableId)
        ..then((scorable) {
          expect(scorable.aggregateId, equals(_aggregateId));
          expect(scorable.name, equals('Test 1'));
        });
    });

    test('AddParticipant succes', () {
      final _aggregateId = ScorableAggregateId.random();
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId)
        ..when(AddParticipant()
          ..scorableId = _aggregateId.scorableId
          ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: ''))
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

    test('RemoveParticipant failed (non-existing participant)', () {
      final _aggregateId = ScorableAggregateId.random();
      final participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Participant 1');
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId)
        ..when(RemoveParticipant()
          ..scorableId = _aggregateId.scorableId
          ..participant = participant)
        ..then((scorable) {
          expect(fixture.lastThrownException.toString(), contains('Participant not on Scorable'));
          expect(scorable.participants.length, equals(0));
        });
    });

  });

  group('Event handling', () {
    late TestFixture<Scorable, ScorableAggregateId> fixture;

    setUp(() {
      fixture = TestFixture<Scorable, ScorableAggregateId>(ScorableCommandHandler(), ScorableEventHandler());
    });

    test('ScorableCreated', () {
      final _aggregateId = ScorableAggregateId.random();
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId)
        ..then((scorable) {
          expect(scorable.name, equals('Test'));
          expect(scorable.aggregateId, equals(_aggregateId));
          expect(scorable.participants.length, equals(0));
        });
    });

    test('ParticipantAdded', () {
      final _aggregateId = ScorableAggregateId.random();
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId)
        ..given(_aggregateId, ParticipantAdded()
          ..scorableId = _aggregateId.scorableId
          ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: ''))
        ..then((scorable) {
          expect(scorable.participants.length, equals(1));
        });
    });

    test('ParticipantRemoved', () {
      final _aggregateId = ScorableAggregateId.random();
      fixture
        ..given(_aggregateId, ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId)
        ..given(_aggregateId, ParticipantRemoved()
          ..scorableId = _aggregateId.scorableId
          ..participant = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: ''))
        ..then((scorable) {
          expect(scorable.participants.length, equals(0));
        });
    });
  });

  group('Scorable Value Objects', () {
    group('Participant', () {

      /// It is important that Value Objects that contain references to other aggregates/entities
      /// are only checking against the referenced entity ID, and not any of the other properties.
      /// This way we can just use the default contains methods etc when checking if a Participant VO is present or not.
      test('Participant should equal on ParticipantId only', () {
        final player1 = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player 1');
        final player1b = Participant(participantId: player1.participantId, participantName: 'Player 2');
        final player2 = Participant(participantId: ParticipantId(uuid: Uuid().v4()), participantName: 'Player 2');
        expect(player1, equals(player1b));
        expect(player1, isNot(equals(player2)));
        expect(player1b, isNot(equals(player2)));
      });
    });
  });

  group('Event serialization', () {

    final serializer = ScorableSerializer();
    final deserializer = ScorableDeserializer();

    test('ScorableCreated', () {
      final _aggregateId = ScorableAggregateId.random();
      final event = ScorableCreated()
          ..name = 'Test'
          ..scorableId = _aggregateId.scorableId;
      final serialized = serializer.serialize(event);
      final deserialized = deserializer.deserialize('ScorableCreated', serialized);
      expect(deserialized, equals(event));
    });
  });


}
