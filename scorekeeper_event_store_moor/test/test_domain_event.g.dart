// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_domain_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestDomainEvent _$TestDomainEventFromJson(Map<String, dynamic> json) {
  return TestDomainEvent(
    json['eventId'] as String,
    DateTime.parse(json['timestamp'] as String),
    json['userId'] as String?,
    json['processId'] as String?,
  );
}

Map<String, dynamic> _$TestDomainEventToJson(TestDomainEvent instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'timestamp': instance.timestamp.toIso8601String(),
      'userId': instance.userId,
      'processId': instance.processId,
    };
