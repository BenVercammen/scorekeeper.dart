
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_domain/core.dart';

import 'aggregate.dart';
import 'event.dart';

/// The Scorekeeper class adds event sourcing capabilities to the actual domain.
/// All commands and events will have to go through this class in order to be handled.
class Scorekeeper {

  final logger = Logger();

  final EventManager _localEventManager;

  final EventManager _remoteEventManager;

  /// Map of aggregates this Scorekeeper needs to follow up on.
  /// In order to receive events from external source,
  /// the relevant Aggregate Id and name needs to be registered in this list
  final Map<AggregateId, Type> _registeredAggregates = HashMap();

  /// The cache in which to store the hydrated aggregate
  final AggregateCache _aggregateCache;

  /// The (generated) handler that maps commands to aggregate handler methods
  final _commandHandlers = <CommandHandler>{};

  /// The (generated) handler that maps events to aggregate handler methods
  final _eventHandlers = <EventHandler>{};

  /// Create a Scorekeeper instance
  Scorekeeper(this._localEventManager, this._remoteEventManager, this._aggregateCache) {
    if (null == _localEventManager) {
      throw Exception('Local EventManager instance is required');
    }
    if (null == _aggregateCache) {
      throw Exception('AggregateCache instance is required');
    }
    if (null == _remoteEventManager) {
      logger.i('No remote event manager was passed along, so all events will remain on the local machine');
    }

    // Make sure that the local event manager keeps track only of the registered AggregateIds
    _localEventManager.registerAggregateIds(_registeredAggregates.keys);

    // Listen to the EventManager streams
    _localEventManager.domainEventStream.listen((DomainEvent event) {
      // If the event relates to an aggregate that's supposed to be cached, we'll handle it, otherwise just let it sit in the store
      if (_aggregateCache.contains(event.aggregateId)) {
        handleEvent(event);
      }
    });
  }

  /// Register the given event handler
  void registerEventHandler(EventHandler handler) {
    _eventHandlers.add(handler);
  }

  /// Unregister the given event handler
  void unregisterEventHandler(EventHandler handler) {
    _eventHandlers.remove(handler);
  }

  /// Register the given command handler
  void registerCommandHandler(CommandHandler handler) {
    _commandHandlers.add(handler);
  }

  /// Unregister the given command handler
  void unregisterCommandHandler(CommandHandler handler) {
    _commandHandlers.remove(handler);
  }

  /// Add an aggregate as being available within the current Scorekeeper instance.
  /// This is important as otherwise aggregates from outside this instance won't be available.
  void registerAggregate(AggregateId aggregateId, Type aggregateType) {
    _registeredAggregates.putIfAbsent(aggregateId, () => aggregateType);
    _localEventManager.registerAggregateId(aggregateId);
  }

  /// Mark an aggregate as no longer being registered.
  /// Removes a "cached" aggregate from this scorekeeper instance and stops listening for (domain) events of that aggregate.
  void unregisterAggregate(AggregateId aggregateId) {
    _registeredAggregates.remove(aggregateId);
    _aggregateCache.purge(aggregateId);
    _localEventManager.unregisterAggregateId(aggregateId);
  }

  /// Handle the given command using the wired (generated) CommandHandler
  void handleCommand(dynamic command) {
    try {
      // ignore: unnecessary_statements
      command.aggregateId;
    // ignore: avoid_catching_errors
    } on NoSuchMethodError {
      throw InvalidCommandException(command);
    }
    if (command.aggregateId == null) {
      throw InvalidCommandException(command);
    }
    // The aggregate on which the command should be applied.
    // We'll use the registered command handler(s) to create a new Aggregate instances based on the given command
    final aggregateId = AggregateId.of(command.aggregateId as String);
    Aggregate aggregate;
    final commandHandler = _getCommandHandlerFor(command);
    if (commandHandler.isConstructorCommand(command)) {
      // First make sure no Aggregate for the given AggregateId exists already
      // For now only in local event manager, but maybe we should check the remote as well?
      // Or somehow allow for updating the aggregateId. The chances of accidentally using duplicate aggregateId's are very slim!
      // When it's done on purpose, tough luck then...
      if (_localEventManager.hasEventsForAggregate(aggregateId)) {
        throw AggregateIdAlreadyExistsException(aggregateId);
      }
      aggregate = commandHandler.handleConstructorCommand(command);
      _aggregateCache.store(aggregate);
    } else {
      if (_aggregateCache.contains(aggregateId)) {
        aggregate = _aggregateCache.get(aggregateId);
      } else {
        // When not yet stored in cache, request events from local event manager and apply them...
        aggregate = commandHandler.newInstance(aggregateId);
        _localEventManager.getEventsForAggregate(aggregateId).forEach((event) {
          aggregate.apply(event.payload);
        });
        _aggregateCache.store(aggregate);
      }
      commandHandler.handle(aggregate, command);
    }
    // Make sure the aggregate is now registered and cached.
    // It makes sense to do so because otherwise events would get lost and there is a high probably new commands will be sent for this aggregate
    registerAggregate(aggregateId, aggregate.runtimeType);
    addAggregateToCache(aggregateId, aggregate.runtimeType);
    if (null != aggregate) {
      // De appliedEvents nog effectief handlen
      final eventHandler = _getEventHandlerFor(aggregate.runtimeType);
      for (var event in aggregate.appliedEvents) {
        final sequence = _getNextSequenceValueForAggregateEvent(aggregate);
        final domainEvent = DomainEvent.of(DomainEventId.local(sequence), aggregate.aggregateId, event);
        eventHandler.handle(aggregate, domainEvent);
        _localEventManager.storeAndPublish(domainEvent);
      }
      aggregate.appliedEvents.clear();
    } else {
      // TODO: wat in dit geval?? fout gooien?? applicatie niet juist gewired?
    }
    // And make sure the aggregate is registered. If this instance is handling commands, it's best that the aggregate is cached
    _localEventManager.registerAggregateId(aggregateId);
  }

  int _getNextSequenceValueForAggregateEvent(Aggregate aggregate) {
    return _localEventManager.countEventsForAggregate(aggregate.aggregateId) + 1;
  }

  /// Handle the given event using the wired (generated) EventHandler
  /// We don't pass the aggregate, each event should have the "aggregateId"...
  /// TODO: of course, we might want to work with DomainEvent classes, add some extra "typing" here?
  void handleEvent(DomainEvent domainEvent) {
    // Kijken of we de aggregate van dit event in't oog houden of niet...
    final aggregateId = domainEvent.aggregateId;
    if (!_registeredAggregates.containsKey(aggregateId)) {
      // TODO: loggen? nu negeren we deze gewoon...
      // TODO: Of tenminste het event opslaan! (aparte lijst voor events voorzien, naast lijst met aggregates??)
      // TODO: we moeten wel de "origin event" hebben, zodat we weten dat we compleet zijn??
      // TODO... of toch event sequences bijhouden per aggregate?
      return;
    }

    // Wanneer we een aggregate binnen Event binnen krijgen voor een aggregate moeten we nagaan dat
    //  1. het een "prevId" heeft, tenzij er nog geen andere events voor binnengekomen zijn
    //  2. we de "prevId" ook al in memory/repository hebben zitten???

    // When there is no previous Id, there should not be any other events for this aggregate in the store...
    // TODO: vervangen door check op event sequence id
    // if (null == domainEvent.id.prevOriginId && !_localEventManager.isInitialAggregateDomainEvent(domainEvent)) {
    //   // TODO: SYSTEM event toevoegen!
    //   throw Exception("TODO: SYSTEM event publishen en verder gaan...");
    // }


    // TODO: en als we geen cache willen bijhouden, maar wel events?
    //  -> gewoon store and publish dan he!
    // Hebben we dit al in cache?
    Aggregate aggregate;
    if (_aggregateCache.contains(aggregateId)) {
      // Een lege, default instance aanmaken en verdere events afhandelen...
      // TODO: of kijken of we nog events hiervoor hebben? zonder dat de aggregate zelf in cache zit?
      aggregate = _aggregateCache.get(aggregateId);
      // TODO: ook nog nagaan dat we effectief alle events al hebben?
    } else {
      // Instance laden
      aggregate = _loadHydratedAggregate(domainEvent.aggregateType, aggregateId);
      // aggregate cachen
      _aggregateCache.store(aggregate);
    }
    // En huidige event apply'en
    _getEventHandlerFor(aggregate.runtimeType).handle(aggregate, domainEvent);
    // event publishen (lokaal en later ook remote??) (dan moet EventId wel aangepast worden)
    // TODO: store and publish moet enkel als het extern binnenkomt, als we het via externe manager binnen krijgen,
    //  is dat niet meer nodig he??
    _localEventManager.storeAndPublish(domainEvent);
  }

  Aggregate _loadHydratedAggregate(Type runtimeType, AggregateId aggregateId) {
    final eventHandler = _getEventHandlerFor(runtimeType);
    // Nieuwe instance maken
    final aggregate = eventHandler.newInstance(aggregateId);
    // Alle events die we al hebben eerst nog apply'en!
    _localEventManager.getEventsForAggregate(aggregateId).forEach((DomainEvent domainEvent) {
      eventHandler.handle(aggregate, domainEvent);
    });
    return aggregate;
  }

  void evictAggregateFromCache(AggregateId aggregateId) {
    _aggregateCache.purge(aggregateId);
  }

  void addAggregateToCache(AggregateId aggregateId, Type aggregateType) {
    if (!_aggregateCache.contains(aggregateId)) {
      final aggregate = _loadHydratedAggregate(aggregateType, aggregateId);
      _aggregateCache.store(aggregate);
    }
  }

  bool isRegistered(AggregateId aggregateId) {
    return _registeredAggregates.containsKey(aggregateId);
  }

  CommandHandler<Aggregate> _getCommandHandlerFor(dynamic command) {
    final handlers = _commandHandlers.where((handler) => handler.handles(command)).toSet();
    if (handlers.isEmpty) {
      throw UnsupportedCommandException(command);
    }
    if (handlers.length > 1) {
      throw MultipleCommandHandlersException(command);
    }
    return handlers.first;
  }

  /// Get the EventHandler for the given Aggregate Type
  EventHandler _getEventHandlerFor(Type runtimeType) {
    return _eventHandlers.where((EventHandler handler) => handler.forType(runtimeType)).first;
  }

}
