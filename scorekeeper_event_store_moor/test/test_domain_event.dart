
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_event_store_moor/event_store_moor.dart';
import 'package:uuid/uuid.dart';

import 'generated/events.pb.dart';

class TestDomainAggregateId extends AggregateId {

  final TestAggregateId testAggregateId;

  @override
  final Type type = TestDomainAggregateId;

  @override
  String get id => testAggregateId.uuid;

  TestDomainAggregateId(this.testAggregateId);

  TestDomainAggregateId._(String id) : testAggregateId = TestAggregateId(uuid: id);

  static TestDomainAggregateId random() {
    return TestDomainAggregateId._(Uuid().v4());
  }

  static TestDomainAggregateId of(String id) {
    return TestDomainAggregateId._(id);
  }
}

// TODO: in domain te laten genereren!!!!
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

// TODO: in domain te laten genereren!
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

}

