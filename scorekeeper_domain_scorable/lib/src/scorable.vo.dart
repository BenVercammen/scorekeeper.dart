part of 'scorable.dart';

/// Value object used within the Scorable aggregate
/// TODO: are we allowed to pass these along? We'll probably have to de-dupe this usage...
///  We now use Participant for 2 purposes:
///   - for working with inside the internal state of the aggregate
///   - for passing along in commands & events
///
/// TODO: another question, should we treat Entity/Aggregate referring VO DTO's differently?
class Participant {

  final String participantId;

  final String name;

  Participant(this.participantId, this.name);

  @override
  String toString() {
    return 'Participant $name ($participantId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Participant && runtimeType == other.runtimeType && participantId == other.participantId;

  @override
  int get hashCode => participantId.hashCode;
}
