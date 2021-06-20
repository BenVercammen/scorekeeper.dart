import 'package:scorekeeper_domain_scorable/src/generated/events.pb.dart';
import 'package:scorekeeper_domain/core.dart';

class ScorableSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
      case EventMetadata:
        return (object as EventMetadata).writeToJson();
      case Participant:
        return (object as Participant).writeToJson();
      case ScorableCreated:
        return (object as ScorableCreated).writeToJson();
      case ParticipantAdded:
        return (object as ParticipantAdded).writeToJson();
      case ParticipantRemoved:
        return (object as ParticipantRemoved).writeToJson();
      case ParticipantStruckOut:
        return (object as ParticipantStruckOut).writeToJson();
      case ParticipantStrikeOutUndone:
        return (object as ParticipantStrikeOutUndone).writeToJson();
      case RoundAdded:
        return (object as RoundAdded).writeToJson();
      case RoundRemoved:
        return (object as RoundRemoved).writeToJson();
      case RoundStarted:
        return (object as RoundStarted).writeToJson();
      case RoundFinished:
        return (object as RoundFinished).writeToJson();
      case RoundPaused:
        return (object as RoundPaused).writeToJson();
      case RoundResumed:
        return (object as RoundResumed).writeToJson();
      default:
        throw Exception('Cannot serialize "${object.runtimeType}"');
    }
  }
}

class ScorableDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      case 'EventMetadata':
        return EventMetadata.fromJson(serialized);
      case 'Participant':
        return Participant.fromJson(serialized);
      case 'ScorableCreated':
        return ScorableCreated.fromJson(serialized);
      case 'ParticipantAdded':
        return ParticipantAdded.fromJson(serialized);
      case 'ParticipantRemoved':
        return ParticipantRemoved.fromJson(serialized);
      case 'ParticipantStruckOut':
        return ParticipantStruckOut.fromJson(serialized);
      case 'ParticipantStrikeOutUndone':
        return ParticipantStrikeOutUndone.fromJson(serialized);
      case 'RoundAdded':
        return RoundAdded.fromJson(serialized);
      case 'RoundRemoved':
        return RoundRemoved.fromJson(serialized);
      case 'RoundStarted':
        return RoundStarted.fromJson(serialized);
      case 'RoundFinished':
        return RoundFinished.fromJson(serialized);
      case 'RoundPaused':
        return RoundPaused.fromJson(serialized);
      case 'RoundResumed':
        return RoundResumed.fromJson(serialized);
      default:
        throw Exception('Cannot deserialize "$payloadType"');
    }
  }

  @override
  AggregateId deserializeAggregateId(String aggregateId, String aggregateType) {
    switch (aggregateType) {
      case 'String':
        return AggregateId.of(aggregateId, String);
      case 'EventMetadata':
        return AggregateId.of(aggregateId, EventMetadata);
      case 'Participant':
        return AggregateId.of(aggregateId, Participant);
      case 'ScorableCreated':
        return AggregateId.of(aggregateId, ScorableCreated);
      case 'ParticipantAdded':
        return AggregateId.of(aggregateId, ParticipantAdded);
      case 'ParticipantRemoved':
        return AggregateId.of(aggregateId, ParticipantRemoved);
      case 'ParticipantStruckOut':
        return AggregateId.of(aggregateId, ParticipantStruckOut);
      case 'ParticipantStrikeOutUndone':
        return AggregateId.of(aggregateId, ParticipantStrikeOutUndone);
      case 'RoundAdded':
        return AggregateId.of(aggregateId, RoundAdded);
      case 'RoundRemoved':
        return AggregateId.of(aggregateId, RoundRemoved);
      case 'RoundStarted':
        return AggregateId.of(aggregateId, RoundStarted);
      case 'RoundFinished':
        return AggregateId.of(aggregateId, RoundFinished);
      case 'RoundPaused':
        return AggregateId.of(aggregateId, RoundPaused);
      case 'RoundResumed':
        return AggregateId.of(aggregateId, RoundResumed);
      default:
        throw Exception('Cannot deserialize AggregateId for "$aggregateType"');
    }
  }
}
