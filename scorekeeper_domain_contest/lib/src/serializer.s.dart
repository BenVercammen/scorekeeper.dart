
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_contest/contest.dart';

class ContestSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
    case ContestCreated:
      return (object as ContestCreated).writeToJson();
    default:
      throw Exception('CANNOT SERIALIZE ${object.runtimeType}');
    }
  }
}

// TODO: in domain te laten genereren!
class ContestDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      case 'ContestCreated':
        return ContestCreated.fromJson(serialized);
      default:
        throw Exception('CANNOT DESERIALIZE "$payloadType"');
    }
  }

}

