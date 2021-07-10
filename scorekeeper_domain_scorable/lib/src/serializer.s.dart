import 'package:scorekeeper_domain_scorable/scorable.dart';
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
  AggregateId deserializeAggregateId(
      String aggregateId, String aggregateTypeName) {
    Type aggregateType;
    switch (aggregateTypeName) {
      case 'String':
        aggregateType = String;
        break;
      case 'MuurkeKlopNDown':
        aggregateType = MuurkeKlopNDown;
        break;
      case 'Scorable':
        aggregateType = Scorable;
        break;
      default:
        throw Exception(
            'Cannot deserialize aggregateId for aggregateType "aggregateTypeName"');
    }
    return AggregateId.of(aggregateId, aggregateType);
  }
}
