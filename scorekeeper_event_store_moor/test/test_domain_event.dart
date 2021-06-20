
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_event_store_moor/event_store_moor.dart';
import 'package:uuid/uuid.dart';

import 'generated/events.pb.dart';

// This class should be generated within the domain...
class TestDomainEventSerializer implements DomainSerializer {
  @override
  String serialize(dynamic object) {
    switch (object.runtimeType) {
      case String:
        return object.toString();
      case TestAggregateCreated:
        return (object as TestAggregateCreated).writeToJson();
      default:
        throw Exception('CANNOT SERIALIZE ${object.runtimeType}');
    }
  }
}

// This class should be generated within the domain...
class TestDomainEventDeserializer implements DomainDeserializer {
  @override
  dynamic deserialize(String payloadType, String serialized) {
    switch (payloadType) {
      case 'String':
        return serialized;
      case 'TestAggregateCreated':
        return TestAggregateCreated.fromJson(serialized);
      default:
        throw Exception('CANNOT DESERIALIZE "$payloadType"');
    }
  }

  @override
  AggregateId deserializeAggregateId(String aggregateId, String aggregateType) {
    switch (aggregateType) {
      case 'String':
        return AggregateId.of(aggregateId, String);
      case 'Aggregate':
        return AggregateId.of(aggregateId, Aggregate);
      default:
        throw Exception('CANNOT DESERIALIZE AggregateId for "$aggregateType"');
    }
  }

}

