
import 'package:json_annotation/json_annotation.dart';

// Path to the generated source code part
// part 'test_domain_event.g.dart';

class TestDomainEvent {
  final String eventId;
  final DateTime timestamp;
  final String? userId;
  final String? processId;

  TestDomainEvent(this.eventId, this.timestamp, this.userId, this.processId);
  //
  // factory TestDomainEvent.fromJson(Map<String, dynamic> json) => _$TestDomainEventFromJson(json);
  //
  // Map<String, dynamic> toJson() => _$TestDomainEventToJson(this);

}
