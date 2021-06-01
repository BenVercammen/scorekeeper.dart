// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_store_moor.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class DomainEventData extends DataClass implements Insertable<DomainEventData> {
  final String eventId;
  final DateTime timestamp;
  final String? userId;
  final String? processId;
  final String producerId;
  final String applicationVersion;
  final String domainId;
  final String domainVersion;
  final String aggregateId;
  final int sequence;
  final String payloadType;
  final String payload;
  DomainEventData(
      {required this.eventId,
      required this.timestamp,
      this.userId,
      this.processId,
      required this.producerId,
      required this.applicationVersion,
      required this.domainId,
      required this.domainVersion,
      required this.aggregateId,
      required this.sequence,
      required this.payloadType,
      required this.payload});
  factory DomainEventData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return DomainEventData(
      eventId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}event_id'])!,
      timestamp: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
      userId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id']),
      processId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}process_id']),
      producerId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}producer_id'])!,
      applicationVersion: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}application_version'])!,
      domainId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}domain_id'])!,
      domainVersion: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}domain_version'])!,
      aggregateId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}aggregate_id'])!,
      sequence: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sequence'])!,
      payloadType: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}payload_type'])!,
      payload: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}payload'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String?>(userId);
    }
    if (!nullToAbsent || processId != null) {
      map['process_id'] = Variable<String?>(processId);
    }
    map['producer_id'] = Variable<String>(producerId);
    map['application_version'] = Variable<String>(applicationVersion);
    map['domain_id'] = Variable<String>(domainId);
    map['domain_version'] = Variable<String>(domainVersion);
    map['aggregate_id'] = Variable<String>(aggregateId);
    map['sequence'] = Variable<int>(sequence);
    map['payload_type'] = Variable<String>(payloadType);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  DomainEventTableCompanion toCompanion(bool nullToAbsent) {
    return DomainEventTableCompanion(
      eventId: Value(eventId),
      timestamp: Value(timestamp),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      processId: processId == null && nullToAbsent
          ? const Value.absent()
          : Value(processId),
      producerId: Value(producerId),
      applicationVersion: Value(applicationVersion),
      domainId: Value(domainId),
      domainVersion: Value(domainVersion),
      aggregateId: Value(aggregateId),
      sequence: Value(sequence),
      payloadType: Value(payloadType),
      payload: Value(payload),
    );
  }

  factory DomainEventData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return DomainEventData(
      eventId: serializer.fromJson<String>(json['eventId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      userId: serializer.fromJson<String?>(json['userId']),
      processId: serializer.fromJson<String?>(json['processId']),
      producerId: serializer.fromJson<String>(json['producerId']),
      applicationVersion:
          serializer.fromJson<String>(json['applicationVersion']),
      domainId: serializer.fromJson<String>(json['domainId']),
      domainVersion: serializer.fromJson<String>(json['domainVersion']),
      aggregateId: serializer.fromJson<String>(json['aggregateId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      payloadType: serializer.fromJson<String>(json['payloadType']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'userId': serializer.toJson<String?>(userId),
      'processId': serializer.toJson<String?>(processId),
      'producerId': serializer.toJson<String>(producerId),
      'applicationVersion': serializer.toJson<String>(applicationVersion),
      'domainId': serializer.toJson<String>(domainId),
      'domainVersion': serializer.toJson<String>(domainVersion),
      'aggregateId': serializer.toJson<String>(aggregateId),
      'sequence': serializer.toJson<int>(sequence),
      'payloadType': serializer.toJson<String>(payloadType),
      'payload': serializer.toJson<String>(payload),
    };
  }

  DomainEventData copyWith(
          {String? eventId,
          DateTime? timestamp,
          String? userId,
          String? processId,
          String? producerId,
          String? applicationVersion,
          String? domainId,
          String? domainVersion,
          String? aggregateId,
          int? sequence,
          String? payloadType,
          String? payload}) =>
      DomainEventData(
        eventId: eventId ?? this.eventId,
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
        processId: processId ?? this.processId,
        producerId: producerId ?? this.producerId,
        applicationVersion: applicationVersion ?? this.applicationVersion,
        domainId: domainId ?? this.domainId,
        domainVersion: domainVersion ?? this.domainVersion,
        aggregateId: aggregateId ?? this.aggregateId,
        sequence: sequence ?? this.sequence,
        payloadType: payloadType ?? this.payloadType,
        payload: payload ?? this.payload,
      );
  @override
  String toString() {
    return (StringBuffer('DomainEventData(')
          ..write('eventId: $eventId, ')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('processId: $processId, ')
          ..write('producerId: $producerId, ')
          ..write('applicationVersion: $applicationVersion, ')
          ..write('domainId: $domainId, ')
          ..write('domainVersion: $domainVersion, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('sequence: $sequence, ')
          ..write('payloadType: $payloadType, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      eventId.hashCode,
      $mrjc(
          timestamp.hashCode,
          $mrjc(
              userId.hashCode,
              $mrjc(
                  processId.hashCode,
                  $mrjc(
                      producerId.hashCode,
                      $mrjc(
                          applicationVersion.hashCode,
                          $mrjc(
                              domainId.hashCode,
                              $mrjc(
                                  domainVersion.hashCode,
                                  $mrjc(
                                      aggregateId.hashCode,
                                      $mrjc(
                                          sequence.hashCode,
                                          $mrjc(payloadType.hashCode,
                                              payload.hashCode))))))))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DomainEventData &&
          other.eventId == this.eventId &&
          other.timestamp == this.timestamp &&
          other.userId == this.userId &&
          other.processId == this.processId &&
          other.producerId == this.producerId &&
          other.applicationVersion == this.applicationVersion &&
          other.domainId == this.domainId &&
          other.domainVersion == this.domainVersion &&
          other.aggregateId == this.aggregateId &&
          other.sequence == this.sequence &&
          other.payloadType == this.payloadType &&
          other.payload == this.payload);
}

class DomainEventTableCompanion extends UpdateCompanion<DomainEventData> {
  final Value<String> eventId;
  final Value<DateTime> timestamp;
  final Value<String?> userId;
  final Value<String?> processId;
  final Value<String> producerId;
  final Value<String> applicationVersion;
  final Value<String> domainId;
  final Value<String> domainVersion;
  final Value<String> aggregateId;
  final Value<int> sequence;
  final Value<String> payloadType;
  final Value<String> payload;
  const DomainEventTableCompanion({
    this.eventId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.userId = const Value.absent(),
    this.processId = const Value.absent(),
    this.producerId = const Value.absent(),
    this.applicationVersion = const Value.absent(),
    this.domainId = const Value.absent(),
    this.domainVersion = const Value.absent(),
    this.aggregateId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.payload = const Value.absent(),
  });
  DomainEventTableCompanion.insert({
    required String eventId,
    required DateTime timestamp,
    this.userId = const Value.absent(),
    this.processId = const Value.absent(),
    required String producerId,
    required String applicationVersion,
    required String domainId,
    required String domainVersion,
    required String aggregateId,
    required int sequence,
    required String payloadType,
    required String payload,
  })  : eventId = Value(eventId),
        timestamp = Value(timestamp),
        producerId = Value(producerId),
        applicationVersion = Value(applicationVersion),
        domainId = Value(domainId),
        domainVersion = Value(domainVersion),
        aggregateId = Value(aggregateId),
        sequence = Value(sequence),
        payloadType = Value(payloadType),
        payload = Value(payload);
  static Insertable<DomainEventData> custom({
    Expression<String>? eventId,
    Expression<DateTime>? timestamp,
    Expression<String?>? userId,
    Expression<String?>? processId,
    Expression<String>? producerId,
    Expression<String>? applicationVersion,
    Expression<String>? domainId,
    Expression<String>? domainVersion,
    Expression<String>? aggregateId,
    Expression<int>? sequence,
    Expression<String>? payloadType,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (timestamp != null) 'timestamp': timestamp,
      if (userId != null) 'user_id': userId,
      if (processId != null) 'process_id': processId,
      if (producerId != null) 'producer_id': producerId,
      if (applicationVersion != null) 'application_version': applicationVersion,
      if (domainId != null) 'domain_id': domainId,
      if (domainVersion != null) 'domain_version': domainVersion,
      if (aggregateId != null) 'aggregate_id': aggregateId,
      if (sequence != null) 'sequence': sequence,
      if (payloadType != null) 'payload_type': payloadType,
      if (payload != null) 'payload': payload,
    });
  }

  DomainEventTableCompanion copyWith(
      {Value<String>? eventId,
      Value<DateTime>? timestamp,
      Value<String?>? userId,
      Value<String?>? processId,
      Value<String>? producerId,
      Value<String>? applicationVersion,
      Value<String>? domainId,
      Value<String>? domainVersion,
      Value<String>? aggregateId,
      Value<int>? sequence,
      Value<String>? payloadType,
      Value<String>? payload}) {
    return DomainEventTableCompanion(
      eventId: eventId ?? this.eventId,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      processId: processId ?? this.processId,
      producerId: producerId ?? this.producerId,
      applicationVersion: applicationVersion ?? this.applicationVersion,
      domainId: domainId ?? this.domainId,
      domainVersion: domainVersion ?? this.domainVersion,
      aggregateId: aggregateId ?? this.aggregateId,
      sequence: sequence ?? this.sequence,
      payloadType: payloadType ?? this.payloadType,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String?>(userId.value);
    }
    if (processId.present) {
      map['process_id'] = Variable<String?>(processId.value);
    }
    if (producerId.present) {
      map['producer_id'] = Variable<String>(producerId.value);
    }
    if (applicationVersion.present) {
      map['application_version'] = Variable<String>(applicationVersion.value);
    }
    if (domainId.present) {
      map['domain_id'] = Variable<String>(domainId.value);
    }
    if (domainVersion.present) {
      map['domain_version'] = Variable<String>(domainVersion.value);
    }
    if (aggregateId.present) {
      map['aggregate_id'] = Variable<String>(aggregateId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<String>(payloadType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DomainEventTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('processId: $processId, ')
          ..write('producerId: $producerId, ')
          ..write('applicationVersion: $applicationVersion, ')
          ..write('domainId: $domainId, ')
          ..write('domainVersion: $domainVersion, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('sequence: $sequence, ')
          ..write('payloadType: $payloadType, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $DomainEventTableTable extends DomainEventTable
    with TableInfo<$DomainEventTableTable, DomainEventData> {
  final GeneratedDatabase _db;
  final String? _alias;
  $DomainEventTableTable(this._db, [this._alias]);
  final VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedTextColumn eventId = _constructEventId();
  GeneratedTextColumn _constructEventId() {
    return GeneratedTextColumn('event_id', $tableName, false,
        minTextLength: 36, maxTextLength: 36);
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  @override
  late final GeneratedDateTimeColumn timestamp = _constructTimestamp();
  GeneratedDateTimeColumn _constructTimestamp() {
    return GeneratedDateTimeColumn(
      'timestamp',
      $tableName,
      false,
    );
  }

  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedTextColumn userId = _constructUserId();
  GeneratedTextColumn _constructUserId() {
    return GeneratedTextColumn('user_id', $tableName, true,
        minTextLength: 36, maxTextLength: 36);
  }

  final VerificationMeta _processIdMeta = const VerificationMeta('processId');
  @override
  late final GeneratedTextColumn processId = _constructProcessId();
  GeneratedTextColumn _constructProcessId() {
    return GeneratedTextColumn('process_id', $tableName, true,
        minTextLength: 36, maxTextLength: 36);
  }

  final VerificationMeta _producerIdMeta = const VerificationMeta('producerId');
  @override
  late final GeneratedTextColumn producerId = _constructProducerId();
  GeneratedTextColumn _constructProducerId() {
    return GeneratedTextColumn('producer_id', $tableName, false,
        minTextLength: 6, maxTextLength: 36);
  }

  final VerificationMeta _applicationVersionMeta =
      const VerificationMeta('applicationVersion');
  @override
  late final GeneratedTextColumn applicationVersion =
      _constructApplicationVersion();
  GeneratedTextColumn _constructApplicationVersion() {
    return GeneratedTextColumn('application_version', $tableName, false,
        minTextLength: 1, maxTextLength: 36);
  }

  final VerificationMeta _domainIdMeta = const VerificationMeta('domainId');
  @override
  late final GeneratedTextColumn domainId = _constructDomainId();
  GeneratedTextColumn _constructDomainId() {
    return GeneratedTextColumn('domain_id', $tableName, false,
        minTextLength: 6, maxTextLength: 36);
  }

  final VerificationMeta _domainVersionMeta =
      const VerificationMeta('domainVersion');
  @override
  late final GeneratedTextColumn domainVersion = _constructDomainVersion();
  GeneratedTextColumn _constructDomainVersion() {
    return GeneratedTextColumn('domain_version', $tableName, false,
        minTextLength: 1, maxTextLength: 36);
  }

  final VerificationMeta _aggregateIdMeta =
      const VerificationMeta('aggregateId');
  @override
  late final GeneratedTextColumn aggregateId = _constructAggregateId();
  GeneratedTextColumn _constructAggregateId() {
    return GeneratedTextColumn('aggregate_id', $tableName, false,
        minTextLength: 36, maxTextLength: 36);
  }

  final VerificationMeta _sequenceMeta = const VerificationMeta('sequence');
  @override
  late final GeneratedIntColumn sequence = _constructSequence();
  GeneratedIntColumn _constructSequence() {
    return GeneratedIntColumn(
      'sequence',
      $tableName,
      false,
    );
  }

  final VerificationMeta _payloadTypeMeta =
      const VerificationMeta('payloadType');
  @override
  late final GeneratedTextColumn payloadType = _constructPayloadType();
  GeneratedTextColumn _constructPayloadType() {
    return GeneratedTextColumn(
      'payload_type',
      $tableName,
      false,
    );
  }

  final VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedTextColumn payload = _constructPayload();
  GeneratedTextColumn _constructPayload() {
    return GeneratedTextColumn(
      'payload',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [
        eventId,
        timestamp,
        userId,
        processId,
        producerId,
        applicationVersion,
        domainId,
        domainVersion,
        aggregateId,
        sequence,
        payloadType,
        payload
      ];
  @override
  $DomainEventTableTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'domain_event_table';
  @override
  final String actualTableName = 'domain_event_table';
  @override
  VerificationContext validateIntegrity(Insertable<DomainEventData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('process_id')) {
      context.handle(_processIdMeta,
          processId.isAcceptableOrUnknown(data['process_id']!, _processIdMeta));
    }
    if (data.containsKey('producer_id')) {
      context.handle(
          _producerIdMeta,
          producerId.isAcceptableOrUnknown(
              data['producer_id']!, _producerIdMeta));
    } else if (isInserting) {
      context.missing(_producerIdMeta);
    }
    if (data.containsKey('application_version')) {
      context.handle(
          _applicationVersionMeta,
          applicationVersion.isAcceptableOrUnknown(
              data['application_version']!, _applicationVersionMeta));
    } else if (isInserting) {
      context.missing(_applicationVersionMeta);
    }
    if (data.containsKey('domain_id')) {
      context.handle(_domainIdMeta,
          domainId.isAcceptableOrUnknown(data['domain_id']!, _domainIdMeta));
    } else if (isInserting) {
      context.missing(_domainIdMeta);
    }
    if (data.containsKey('domain_version')) {
      context.handle(
          _domainVersionMeta,
          domainVersion.isAcceptableOrUnknown(
              data['domain_version']!, _domainVersionMeta));
    } else if (isInserting) {
      context.missing(_domainVersionMeta);
    }
    if (data.containsKey('aggregate_id')) {
      context.handle(
          _aggregateIdMeta,
          aggregateId.isAcceptableOrUnknown(
              data['aggregate_id']!, _aggregateIdMeta));
    } else if (isInserting) {
      context.missing(_aggregateIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('payload_type')) {
      context.handle(
          _payloadTypeMeta,
          payloadType.isAcceptableOrUnknown(
              data['payload_type']!, _payloadTypeMeta));
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  DomainEventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return DomainEventData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $DomainEventTableTable createAlias(String alias) {
    return $DomainEventTableTable(_db, alias);
  }
}

class RegisteredAggregateData extends DataClass
    implements Insertable<RegisteredAggregateData> {
  final String aggregateId;
  final DateTime timestamp;
  RegisteredAggregateData({required this.aggregateId, required this.timestamp});
  factory RegisteredAggregateData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return RegisteredAggregateData(
      aggregateId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}aggregate_id'])!,
      timestamp: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}timestamp'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['aggregate_id'] = Variable<String>(aggregateId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  RegisteredAggregateTableCompanion toCompanion(bool nullToAbsent) {
    return RegisteredAggregateTableCompanion(
      aggregateId: Value(aggregateId),
      timestamp: Value(timestamp),
    );
  }

  factory RegisteredAggregateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RegisteredAggregateData(
      aggregateId: serializer.fromJson<String>(json['aggregateId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'aggregateId': serializer.toJson<String>(aggregateId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  RegisteredAggregateData copyWith(
          {String? aggregateId, DateTime? timestamp}) =>
      RegisteredAggregateData(
        aggregateId: aggregateId ?? this.aggregateId,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('RegisteredAggregateData(')
          ..write('aggregateId: $aggregateId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(aggregateId.hashCode, timestamp.hashCode));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegisteredAggregateData &&
          other.aggregateId == this.aggregateId &&
          other.timestamp == this.timestamp);
}

class RegisteredAggregateTableCompanion
    extends UpdateCompanion<RegisteredAggregateData> {
  final Value<String> aggregateId;
  final Value<DateTime> timestamp;
  const RegisteredAggregateTableCompanion({
    this.aggregateId = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  RegisteredAggregateTableCompanion.insert({
    required String aggregateId,
    required DateTime timestamp,
  })  : aggregateId = Value(aggregateId),
        timestamp = Value(timestamp);
  static Insertable<RegisteredAggregateData> custom({
    Expression<String>? aggregateId,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (aggregateId != null) 'aggregate_id': aggregateId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  RegisteredAggregateTableCompanion copyWith(
      {Value<String>? aggregateId, Value<DateTime>? timestamp}) {
    return RegisteredAggregateTableCompanion(
      aggregateId: aggregateId ?? this.aggregateId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (aggregateId.present) {
      map['aggregate_id'] = Variable<String>(aggregateId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegisteredAggregateTableCompanion(')
          ..write('aggregateId: $aggregateId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RegisteredAggregateTableTable extends RegisteredAggregateTable
    with TableInfo<$RegisteredAggregateTableTable, RegisteredAggregateData> {
  final GeneratedDatabase _db;
  final String? _alias;
  $RegisteredAggregateTableTable(this._db, [this._alias]);
  final VerificationMeta _aggregateIdMeta =
      const VerificationMeta('aggregateId');
  @override
  late final GeneratedTextColumn aggregateId = _constructAggregateId();
  GeneratedTextColumn _constructAggregateId() {
    return GeneratedTextColumn('aggregate_id', $tableName, false,
        minTextLength: 36, maxTextLength: 36);
  }

  final VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  @override
  late final GeneratedDateTimeColumn timestamp = _constructTimestamp();
  GeneratedDateTimeColumn _constructTimestamp() {
    return GeneratedDateTimeColumn(
      'timestamp',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [aggregateId, timestamp];
  @override
  $RegisteredAggregateTableTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'registered_aggregate_table';
  @override
  final String actualTableName = 'registered_aggregate_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<RegisteredAggregateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('aggregate_id')) {
      context.handle(
          _aggregateIdMeta,
          aggregateId.isAcceptableOrUnknown(
              data['aggregate_id']!, _aggregateIdMeta));
    } else if (isInserting) {
      context.missing(_aggregateIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {aggregateId};
  @override
  RegisteredAggregateData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return RegisteredAggregateData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $RegisteredAggregateTableTable createAlias(String alias) {
    return $RegisteredAggregateTableTable(_db, alias);
  }
}

abstract class _$EventStoreMoorImpl extends GeneratedDatabase {
  _$EventStoreMoorImpl(QueryExecutor e)
      : super(SqlTypeSystem.defaultInstance, e);
  late final $DomainEventTableTable domainEventTable =
      $DomainEventTableTable(this);
  late final $RegisteredAggregateTableTable registeredAggregateTable =
      $RegisteredAggregateTableTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [domainEventTable, registeredAggregateTable];
}
