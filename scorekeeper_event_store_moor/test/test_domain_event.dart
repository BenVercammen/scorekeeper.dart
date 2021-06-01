
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_event_store_moor/event_store_moor.dart';

// Path to the generated source code part
part 'test_domain_event.g.dart';

@JsonSerializable()
class TestDomainEvent {
  final String eventId;
  final DateTime timestamp;
  final String? userId;
  final String? processId;

  TestDomainEvent(this.eventId, this.timestamp, this.userId, this.processId);

  factory TestDomainEvent.fromJson(Map<String, dynamic> json) => _$TestDomainEventFromJson(json);

  Map<String, dynamic> toJson() => _$TestDomainEventToJson(this);

}


// TODO: in domain te laten genereren!
class TestDomainEventSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
      case TestDomainEvent:
        return jsonEncode((object as TestDomainEvent).toJson());
      default:
        throw Exception('CANNOT SERIALIZE ${object.runtimeType}');
    }
  }
}

// TODO: in domain te laten genereren!
class TestDomainEventDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      case 'TestDomainEvent':
        return TestDomainEvent.fromJson(jsonDecode(serialized) as Map<String, dynamic>);
      default:
        throw Exception('CANNOT DESERIALIZE "$payloadType"');
    }
  }

}

