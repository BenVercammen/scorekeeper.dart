
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

/// Aggregate specifically for the Muurke Klop N-down type game
@aggregate
class MuurkeKlopNDown extends Scorable {

  final Map<int, Round> rounds = Map();

  MuurkeKlopNDown.aggregateId(AggregateId aggregateId) : super.aggregateId(aggregateId);

  @commandHandler
  MuurkeKlopNDown.command(CreateScorable command) : super.command(command);

  @commandHandler
  void addRound(AddRound command) {
    final event = RoundAdded()
      ..aggregateId = command.aggregateId
      ..roundIndex = rounds.length;
    apply(event);
  }

  @commandHandler
  void removeRound(RemoveRound command) {
    final event = RoundRemoved()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex;
    apply(event);
  }

  @commandHandler
  void strikeOutParticipant(StrikeOutParticipant command) {

    // TODO: check if participant wasn't already striked out... or roundindex is correct, or ...

    final event = ParticipantStrikedOut()
      ..aggregateId = command.aggregateId
      ..roundIndex = command.roundIndex
      ..participant = command.participant;
    apply(event);
  }

  @eventHandler
  void roundAdded(RoundAdded event) {
    final round = Round(event.roundIndex);
    rounds.putIfAbsent(round.roundIndex, () => round);
  }

  @eventHandler
  void roundRemoved(RoundRemoved event) {
    rounds.remove(event.roundIndex);
  }

  @eventHandler
  void participantStrikedOut(ParticipantStrikedOut event) {
    final round = rounds[event.roundIndex];
    round.strikeOutParticipant(event.participant);
  }

}