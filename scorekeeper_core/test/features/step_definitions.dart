
import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:ogurets/ogurets.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_domain/core.dart';

/// Simple mock implementation we can use to mock incoming DomainEvents
class MockRemoteEventListener extends RemoteEventListener {

  final StreamController<DomainEvent> _domainEventController = StreamController<DomainEvent>();

  void emitEvent(DomainEvent domainEvent) {
    _domainEventController.add(domainEvent);
  }

  @override
  Stream<DomainEvent> get domainEventStream => _domainEventController.stream.asBroadcastStream();

}

/// Simple mock implementation we can use to mock outgoing DomainEvents
class MockRemoteEventPublisher extends RemoteEventPublisher {

  final publishedDomainEvents = List<DomainEvent>.empty(growable: true);

  @override
  void publishDomainEvent(DomainEvent domainEvent) {
    publishedDomainEvents.add(domainEvent);
  }

}

class StepDefinitions {

  late TracingLogger _logger;

  late EventStore _localEventManager;

  late MockRemoteEventPublisher _remoteEventPublisher;

  late MockRemoteEventListener _remoteEventListener;

  late DomainEventFactory _domainEventFactory;

  @Before()
  void setUp() {
    _logger = TracingLogger();
    _localEventManager = EventStoreInMemoryImpl(_logger);
    _remoteEventListener = MockRemoteEventListener();
    _remoteEventPublisher = MockRemoteEventPublisher();
    _domainEventFactory = DomainEventFactory(producerId: 'stepdeftests', applicationVersion: 'TODO-applicationVersion');
  }

  // TODO: https://github.com/dart-ogurets/Ogurets (eventueel contribution om duidelijk te maken dat aantal parameters niet klopt (nu onduidelijke growable array error)
  //  Exception: RangeError (index): Invalid value: Valid value range is empty: 0


  @Given(r'the following DomainEvents have already been stored locally')
  Future<void> givenLocalEventManagerHasDomainEvents({required GherkinTable table}) async {
    final givenDomainEvents = _parseDomainEvents(table);
    for (final domainEvent in givenDomainEvents) {
      _localEventManager
          ..registerAggregateId(domainEvent.aggregateId);
      await _localEventManager.storeDomainEvent(domainEvent);
    }
  }

  @When(r'the following DomainEvents are to be stored locally')
  Future<void> eventManagerReceivesRemoteDomainEvents({required GherkinTable table}) async {
    final receivedDomainEvents = _parseDomainEvents(table);
    for (final domainEvent in receivedDomainEvents) {
      await _localEventManager.storeDomainEvent(domainEvent);
    }
  }

  @When(r'the following DomainEvents are received remotely')
  Future<void> eventManagerReceivesLocalDomainEvents({required GherkinTable table}) async {
    final receivedDomainEvents = _parseDomainEvents(table);
    for (final domainEvent in receivedDomainEvents) {
      _remoteEventListener.emitEvent(domainEvent);
    }
  }

  @Then(r'the following DomainEvents should be stored locally')
  Future<void> localEventManagerShouldHaveTheFollowingDomainEvents({required GherkinTable table}) async {
    final expectedDomainEvents = List.from(_parseDomainEvents(table));
    final actualDomainEvents = await _localEventManager.getDomainEvents().toList();
    _collectionShouldContainExactlyInAnyOrder(expectedDomainEvents, actualDomainEvents);
  }

  @Then(r'the following DomainEvents should be published remotely')
  Future<void> domainEventsShouldBePublishedRemotely({required GherkinTable table}) async {
    final expectedDomainEvents = List.from(_parseDomainEvents(table));
    final actualDomainEvents = List.from(_remoteEventPublisher.publishedDomainEvents);
    _collectionShouldContainExactlyInAnyOrder(expectedDomainEvents, actualDomainEvents);
  }

  @Then(r'a level {string} message should be logged stating {string}')
  Future<void> thenMessageShouldBeLogged(String levelName, String expectedMessage) async {
    final level = Level.values.where((element) => element.toString().toLowerCase() == levelName.toLowerCase()).first;
    _logger.loggedMessages.putIfAbsent(level, () => List.empty(growable: true));
    final matches = _logger.loggedMessages[level]?.where((loggedMessage) => loggedMessage.contains(expectedMessage));
    assert(matches!.isNotEmpty);
  }

  /// Assert that actual collection contains exactly all elements of the expected collection, in any order.
  void _collectionShouldContainExactlyInAnyOrder(Iterable expected, Iterable actual) {
    final unmatchedExpected = expected.where((element) => !actual.contains(element));
    final unmatchedActual = actual.where((element) => !expected.contains(element));
    assert(unmatchedActual.isEmpty);
    assert(unmatchedExpected.isEmpty);
  }

  /// Parse a GherkinTable into a List of DomainEvents
  List<DomainEvent<Aggregate, AggregateId>> _parseDomainEvents(GherkinTable table) {
    final domainEvents = List<DomainEvent<Aggregate, AggregateId>>.empty(growable: true);
    final keys = <String>{'eventUuid', 'eventSequence', 'eventTimestamp', 'aggregateId', 'payload.type', 'payload.property1'};
    final parsedRows = _parseTableAsListMap(table, keys);
    for (final row in parsedRows) {
      final payload = _eventPayloadFor(row['payload.type']!, row['payload.property1']!);
      final event = _domainEventFactory.remote(row['eventUuid']!, AggregateId.of(row['aggregateId']!), int.parse(row['eventSequence']!), DateTime.parse(row['eventTimestamp']!), payload);
      domainEvents.add(event);
    }
    return domainEvents;
  }

  /// Get the value out of a table row based on the index of the given key
  String? _getTableValue(Map<String, int> headerIndexes, List<String> split, String key) {
    return headerIndexes.containsKey(key) && headerIndexes[key]! >= 0 ? split[headerIndexes[key]!].trim() : null;
  }

  /// Get a map of table header keys and their respective indexes
  Map<String, int> _getHeaderIndexMap(GherkinTable table) {
    final headers = table.gherkinRows()[0].split('|');
    final headerMap = HashMap<String, int>();
    var index = 0;
    for (final header in headers) {
      headerMap.putIfAbsent(header.trim(), () => index++);
    }
    return headerMap;
  }

  /// Turn a GherkinTable into a List of Map values, extracting the given keys as key => value pairs from the table rows.
  List<Map<String, String?>> _parseTableAsListMap(GherkinTable table, Set<String> keys) {
    final headerIndexes = _getHeaderIndexMap(table);
    final parsedValues = List<Map<String, String?>>.empty(growable: true);
    table.gherkinRows().getRange(1, table.gherkinRows().length).map((element) {
      final split = element.trim().split('|');
      final entryMap = HashMap<String, String?>();
      for (final key in keys) {
        final value = _getTableValue(headerIndexes, split, key);
        entryMap.putIfAbsent(key, () => value);
      }
      parsedValues.add(entryMap);
    }).toList();
    return parsedValues;
  }

  /// Instantiate a dummy event payload
  dynamic _eventPayloadFor(String type, String property1) {
    switch (type) {
      case 'ConstructorEvent':
        return ConstructorEvent(property1);
      case 'RegularEvent':
        return RegularEvent(property1);
      default:
        throw Exception('Unsupported payload type "$type"');
    }
  }

}

class ConstructorEvent {

  final String property1;

  ConstructorEvent(this.property1);

  // It's important that events also have a proper equals implementation
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstructorEvent && runtimeType == other.runtimeType && property1 == other.property1;

  @override
  int get hashCode => property1.hashCode;

}

class RegularEvent {

  final String property1;

  RegularEvent(this.property1);

  // It's important that events also have a proper equals implementation
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegularEvent && runtimeType == other.runtimeType && property1 == other.property1;

  @override
  int get hashCode => property1.hashCode;

}

