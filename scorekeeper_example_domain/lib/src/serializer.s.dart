///
/// Probleem nu is dat we nog via die @Serializable nog een en ander moeten laten genereren,
/// om tot deze code te komen...
/// Tenzij we zelf die code genereren op een of andere manier...
///   ->
///
///
/// EG:
///
///      TestDomainEvent _$TestDomainEventFromJson(Map<String, dynamic> json) {
///        return TestDomainEvent(
///          json['eventId'] as String,
///          DateTime.parse(json['timestamp'] as String),
///          json['userId'] as String?,
///          json['processId'] as String?,
///        );
///      }
///
///      Map<String, dynamic> _$TestDomainEventToJson(TestDomainEvent instance) =>
///          <String, dynamic>{
///            'eventId': instance.eventId,
///            'timestamp': instance.timestamp.toIso8601String(),
///            'userId': instance.userId,
///            'processId': instance.processId,
///          };
///
///



// TODO: in domain te laten genereren!
import 'package:scorekeeper_domain/core.dart';

class ExampleDomainSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
      // case ExampleDomain:
      //   return jsonEncode((object as ExampleDomain).toJson());

      default:
        throw Exception('CANNOT SERIALIZE ${object.runtimeType}');
    }
  }
}

// TODO: in domain te laten genereren!
class ExampleDomainDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      // case 'ExampleDomain':
      //   return ExampleDomain.fromJson(jsonDecode(serialized) as Map<String, dynamic>);
      default:
        throw Exception('CANNOT DESERIALIZE "$payloadType"');
    }
  }

}

