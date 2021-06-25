
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';

/// The (root) aggregate of our domain
/// It is possible to extend this one. The generated handler classes will also contain these handler methods.
/// TODO: only strange thing is the "CreateScorable" command that can be inherited
///  well, actually a custom constructor is required (or handler generator will fail)
///  but I guess that's the only command/event combo that explicitly uses "Scorable" in its name?
///
/// The reason why we want this to be overridable, is because we want to allow
/// for multiple types of scorables within a single domain.
///  eg: muurke klop = N-down + 3-strikes-out
///  -> depending on the stage, the scorable type is different
///

// TODO: oké, eigenlijk stom da'k hier 2 dinges doe he, zowel extenden als annoteren!
// Die annotatie mag in principe weg dan...
@aggregate
class Scorable extends Aggregate {

  late String name;

  final List<Participant> participants = List.empty(growable: true);

  Scorable.aggregateId(AggregateId scorableId) : super(scorableId);

  @commandHandler
  /// TODO: OKE, aggregateId moet ook meegegeven worden!!??
  /// hier zit ik dus nog te worstelen met inheritance ... :/ moet nu "MuurkeKlopNDown" meegeven ipv "Scorable"
  /// anders wordt er een extra AggregateId aangemaakt, omdat die super/sub classes niet matchen...
  Scorable.command(CreateScorable command) : super(AggregateId.of(command.scorableId, MuurkeKlopNDown)) {
    final event = ScorableCreated(
        // TODO: metadata zetten!?
        metadata: null,
        scorableId: command.scorableId,
        name: command.name);
    apply(event);
  }

  @commandHandler
  void addParticipant(AddParticipant command) {
    final participant = command.participant;
    if (participants.contains(participant)) {
      throw Exception('Participant already added to Scorable');
    }
    final event = ParticipantAdded(
      metadata: null,
      scorableId: command.scorableId,
      participant: Participant(
        participantId: command.participant.participantId,
        participantName: command.participant.participantName)
    );
    apply(event);
  }

  @commandHandler
  void removeParticipant(RemoveParticipant command) {
    final participant = command.participant;
    if (!participants.contains(participant)) {
      throw Exception('Participant not on Scorable');
    }
    final event = ParticipantRemoved(
        metadata: null,
        scorableId: command.scorableId,
        participant: Participant(
            participantId: command.participant.participantId,
            participantName: command.participant.participantName)
    );
    apply(event);
  }

  @eventHandler
  void handleScorableCreated(ScorableCreated event) {
    name = event.name;
  }

  @eventHandler
  void handleParticipantAdded(ParticipantAdded event) {
    participants.add(event.participant);
  }

  @eventHandler
  void handleParticipantRemoved(ParticipantRemoved event) {
    // TODO: evt op id ipv object... (equals moet in dit geval in Participant juist geimplementeerd zijn!)
    participants.remove(event.participant);
  }

  // @override
  // String toString() {
  //   return 'Scorable $name ($aggregateId)';
  // }

  /// Is it possible to provide a method that returns the currently allowed commands?
  /// This works on multiple levels
  ///   - the main command level, without taking actual parameters into account
  ///       eg: Scorable is not yet started && minimal numer of participants is available -> StartScorable
  ///       actually, this translates to a map of <"Command" => "isAllowed+Reason">
  ///   - the command content level, taking actual parameters into account
  ///       eg: Participant 1 is already struck out for a given round, so he cannot strike-out again
  ///       this translates to a map of <"Command" => <"Participant" => "isAllowed+Reason">>
  ///       -> but then again, any parameter of the command can be a reason for allowing or disallowing it
  ///       -> so we'd have to create an entire permutation map, which could become quite big quite easily...
  ///       -> still, if done properly, the UI could greatly benefit from this, since we already block certain "buttons"
  ///          based on the current state...
  ///   => in the end, we'd be checking the resulting Map of allowances and disable/enable command buttons based on it
  ///     -> in our current implementation however, we're in luck because the aggregate model is available on the (flutter) client
  ///     -> this means we could potentially call a "isCommandAllowed" method on the AggregateDto
  ///         -> instead of prematurely creating a Map that would probably contain more allowances than we care for
  ///            we'd just have the DTO answer the question when asked...
  ///     => of course, when doing REST, we'll still have to ask these questions, but that's not our problem right now
  ///
  /// We could possibly add and update a list on each event with the "main level commands",
  /// but that would probably just be some premature optimzation...
  ///
  /// Checks whether or not the given command is currently allowed.
  /// This depends on the state of the aggregate and the attribute values of the command itself.
  ///
  /// TODO: shouldn't we "disallow" by default? unknown commands aren't allowed?
  CommandAllowance isAllowed(dynamic command) {
    switch (command.runtimeType) {
      default:
        return CommandAllowance(command, true, 'Allowed by default');
    }
  }

}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// TODO: the classes below are events, commands and value objects that are to be generated with protobuf.
/// however, this also means they cannot implement anything...
/// we either have to create "wrapper classes" in our application (meh)
/// or use reflection...
/// hmm, het reflection path geeft in flutter al problemen...
/// de wrapper classes zijn extra werk, maar dan is het wel "type safe"
///
/// Probleem hiermee is da'k dan in de handlers nog steeds die extended commands moet gebruiken als arguments
/// dus type-gewijs ben ik er nog altijd niet veel mee... :/
///
/// Ik wil niet dat ik in de aggregate zelf met gegenereerde/wrapper classes moet werken......
/// pff, ik wil toch reflection blijven gebruiken :/
/// tenzij die aggregates én die commands én events dus allemaal door een "compilatie" fase moeten gaan...
///   -> ik schrijf een domain lib, heel droog en sec, met de nodige protobufs voor events, commands, value-objects, ...
///   -> die lib moet dan "samen met de applicatie" "gecompileerd" worden?
///     - dependency binnen trekken
///     - gradle build scriptje om domain classes te enrichen
///     - klaar?
///     - wel voos, dien extra stap ertussen...
///     -> zou eigenlijk het domain package moeten builden zodanig dat de generated code enriched wordt?
///
/// https://medium.com/flutter-community/part-1-code-generation-in-dart-the-basics-3127f4c842cc
///   source_gen + build_runner


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// OKAY, these classes have been moved..
