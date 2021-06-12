import 'package:scorekeeper_domain_contest/src/generated/events.pb.dart';
import 'package:scorekeeper_domain/core.dart';

class ContestSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
      case EventMetadata:
        return (object as EventMetadata).writeToJson();
      case ContestCreated:
        return (object as ContestCreated).writeToJson();
      default:
        throw Exception('Cannot serialize "${object.runtimeType}"');
    }
  }
}

class ContestDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      case 'EventMetadata':
        return EventMetadata.fromJson(serialized);
      case 'ContestCreated':
        return ContestCreated.fromJson(serialized);
      default:
        throw Exception('Cannot deserialize "$payloadType"');
    }
  }
}
