
part of 'scorable.dart';

/// Command to create a new Scorable
class CreateScorable {
  late String aggregateId;
  late String name;
}

/// Command to add a Participant to a Scorable
/// TODO: moet ik in die commands en events ook niet meegeven voor welk type aggregate die gelden?
/// alleszins expliciet maken dat het aan een Scorable toegevoegd wordt? desnoods in naamgeving?
class AddParticipant {
  late String aggregateId;
  late Participant participant;
}

class RemoveParticipant {
  late String aggregateId;
  /// Note that we use a full participant object, and not just the ID.
  /// This way we might get some extra details about the user's state
  /// at the time of removal. This could be used in the command handler to
  /// determine whether or not the participant is actually allowed to be removed.
  late Participant participant;
}

class StartScorable {
  late String aggregateId;
}

class FinishScorable {
  late String aggregateId;
}
