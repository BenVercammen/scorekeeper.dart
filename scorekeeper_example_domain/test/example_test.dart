
import 'package:example_domain/example.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';


void main() {
  group('Command handling', () {

    setUp(() {
    });

    test('CreateScorable success', () {
      final _aggregateId = Uuid().v4();
      var createScorableCommand = CreateScorable()
        ..name = 'Test 1'
        ..aggregateId = _aggregateId;
      var scorable = Scorable.command(createScorableCommand);
      expect(scorable.aggregateId, equals(AggregateId.of(_aggregateId)));
      expect(scorable.name, equals('Test 1'));
    });

    test('AddParticipant succes', () {
      var scorable = Scorable.aggregateId(AggregateId.of(Uuid().v4()));
      expect(scorable.participants.length, equals(0));
      var command = AddParticipant()
        ..participant = Participant();
      scorable.addParticipant(command);
      expect(scorable.participants.length, equals(1));
    });

  });
}
