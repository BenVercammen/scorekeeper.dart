
import 'dart:collection';

import 'package:ogurets/ogurets.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';

class StepDefinitions {

  EventManager _localEventManager;

  EventManager _remoteEventManager;

  /// All DomainEvents that have been emitted by the _localEventManager
  List<DomainEvent> _locallyEmittedEvents;

  @Before()
  void setUp() {
    _localEventManager = EventManagerInMemoryImpl();
    _remoteEventManager = EventManagerInMemoryImpl();
    _locallyEmittedEvents = List<DomainEvent>.empty(growable: true);
    _localEventManager.domainEventStream.listen((event) => _locallyEmittedEvents.add(event));
  }

  // TODO: https://github.com/dart-ogurets/Ogurets (eventueel contribution om duidelijk te maken dat aantal parameters niet klopt (nu onduidelijke growable array error)
  //  Exception: RangeError (index): Invalid value: Valid value range is empty: 0


  @Given(r'local EventManager has DomainEvents')
  Future<void> givenLocalEventManagerHasDomainEvents({GherkinTable table}) async {
    final givenDomainEvents = _parseDomainEvents(table);
    for (final domainEvent in givenDomainEvents) {
      _localEventManager.registerAggregateId(domainEvent.aggregateId);
      _localEventManager.store(domainEvent);
    }
  }

  @When(r'local EventManager receives DomainEvents')
  void localEventManagerReceivesDomainEvents({GherkinTable table}) async {
    final receivedDomainEvents = _parseDomainEvents(table);
    for (final domainEvent in receivedDomainEvents) {
      _localEventManager.storeAndPublish(domainEvent);
    }
  }

  @Then(r'local EventManager should have the following DomainEvents')
  void localEventManagerShouldHaveTheFollowingDomainEvents({GherkinTable table}) async {
    final expectedDomainEvents = List.from(_parseDomainEvents(table));
    final actualDomainEvents = List.from(_localEventManager.getAllDomainEvents());
    _collectionShouldContainExactlyInAnyOrder(expectedDomainEvents, actualDomainEvents);
  }

  /// Assert that actual collection contains exactly all elements of the expected collection, in any order.
  void _collectionShouldContainExactlyInAnyOrder(Iterable expected, Iterable actual) {
    final unmatchedExpected = expected.where((element) => !actual.contains(element));
    final unmatchedActual = actual.where((element) => !expected.contains(element));
    assert(unmatchedActual.isEmpty);
    assert(unmatchedExpected.isEmpty);
  }

  /// Parse a GherkinTable into a List of DomainEvents
  List<DomainEvent<Aggregate>> _parseDomainEvents(GherkinTable table) {
    final domainEvents = List<DomainEvent<Aggregate>>.empty(growable: true);
    final keys = <String>{'eventUuid', 'eventSequence', 'eventTimestamp', 'aggregateId', 'payload.type', 'payload.property1'};
    final parsedRows = _parseTableAsListMap(table, keys);
    for (final row in parsedRows) {
      final eventId = DomainEventId.of(row['eventUuid'], int.parse(row['eventSequence']), DateTime.parse(row['eventTimestamp']));
      final payload = _eventPayloadFor(row['payload.type'], row['payload.property1']);
      final event = DomainEvent.of(eventId, AggregateId.of(row['aggregateId']), payload);
      domainEvents.add(event);
    }
    return domainEvents;
  }

  /// Get the value out of a table row based on the index of the given key
  String _getTableValue(Map<String, int> headerIndexes, List<String> split, String key) {
    return headerIndexes.containsKey(key) && headerIndexes[key] >= 0 ? split[headerIndexes[key]].trim() : null;
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
  List<Map<String, String>> _parseTableAsListMap(GherkinTable table, Set<String> keys) {
    final headerIndexes = _getHeaderIndexMap(table);
    final parsedValues = List<Map<String, String>>.empty(growable: true);
    table.gherkinRows().getRange(1, table.gherkinRows().length).map((element) {
      final split = element.trim().split('|');
      final entryMap = HashMap<String, String>();
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

