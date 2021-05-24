import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

import 'aggregate.dart';
import 'event.dart';

/// The Scorekeeper class adds event sourcing capabilities to the actual domain.
/// All commands and events will have to go through this class in order to be handled.
class Scorekeeper {
  Logger _logger = Logger();

  /// The EventStore for storing DomainEvents of the local Scorekeeper instance
  late EventStore _eventStore;

  /// Map of aggregates this Scorekeeper needs to follow up on.
  /// In order to receive events from external source,
  /// the relevant Aggregate Id and name needs to be registered in this list
  final Map<AggregateId, Type> _registeredAggregates = HashMap();

  /// The cache in which to store the hydrated aggregate
  late AggregateCache _aggregateCache;

  /// The DomainEventFactory.
  /// Needs to be created/injected as it is responsible for setting metadata
  /// that we can only retrieve at runtime.
  late final DomainEventFactory _domainEventFactory;

  /// The (generated) handler that maps commands to aggregate handler methods
  final _commandHandlers = <CommandHandler>{};

  /// The (generated) handler that maps events to aggregate handler methods
  final _eventHandlers = <EventHandler>{};

  /// The publisher for emitting DomainEvents to a remote (Scorekeeper) instance
  RemoteEventPublisher? _remoteEventPublisher;

  /// The listener for receiving DomainEvents from a remote (Scorekeeper) instance
  RemoteEventListener? _remoteEventListener;

  /// Create a Scorekeeper instance
  /// EventStore and AggregateCache are required.
  /// RemoteEventPublisher and RemoteEventListener are optional
  Scorekeeper({required EventStore eventStore,
    required AggregateCache aggregateCache,
    required DomainEventFactory domainEventFactory,
    RemoteEventPublisher? remoteEventPublisher,
    RemoteEventListener? remoteEventListener,
    Logger? logger}) {
    _logger = logger ?? Logger();
    _eventStore = eventStore;
    _aggregateCache = aggregateCache;
    _domainEventFactory = domainEventFactory;
    if (null == remoteEventPublisher) {
      _logger.i('No remote event publisher was passed along, so all events will remain on the local machine');
    }
    _remoteEventPublisher = remoteEventPublisher;
    if (null == remoteEventListener) {
      _logger.i('No remote event listener was passed along, so no remote events will be applied on the local machine');
    }
    _remoteEventListener = remoteEventListener;
    // Make sure that the local event manager keeps track only of the registered AggregateIds
    _eventStore.registerAggregateIds(_registeredAggregates.keys);

    // Listen to the RemoteEventListener's event stream
    _remoteEventListener?.domainEventStream.listen((DomainEvent event) async {
      _logger.d('Received remote event');
      // If the event relates to an aggregate that's supposed to be stored, we'll store it
      if (_registeredAggregates.containsKey(event.aggregateId)) {
        try {
          await _eventStore.storeDomainEvent(event);
          // If the event relates to a cached aggregate, we'll handle it immediately
          if (_aggregateCache.contains(event.aggregateId)) {
            await _handleRemoteEvent(event);
          }
        } on Exception catch (exception) {
          _logger.w(exception);
          await _eventStore.storeSystemEvent(_domainEventFactory.eventNotHandled(event, exception.toString()));
        }
      } else {
        _logger.d('ignored event because the aggregateId was not registered');
      }
    });
  }

  /// Get the registered AggregateIds
  Set<AggregateId> get registeredAggregateIds => Set.from(_registeredAggregates.keys);

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
    _eventStore.registerAggregateId(aggregateId);
  }

  /// Mark an aggregate as no longer being registered.
  /// Removes a "cached" aggregate from this scorekeeper instance and stops listening for (domain) events of that aggregate.
  void unregisterAggregate(AggregateId aggregateId) {
    _registeredAggregates.remove(aggregateId);
    _aggregateCache.purge(aggregateId);
    _eventStore.unregisterAggregateId(aggregateId);
  }

  /// Handle the given command using the wired (generated) CommandHandler
  Future<void> handleCommand(dynamic command) async {
    _validateCommand(command);
    final aggregate = await _handleCommand(command);
    // Make sure the aggregate is now registered and cached.
    // It makes sense to do so because otherwise events would get lost and there is a high probably new commands will be sent for this aggregate
    await _cacheAndRegisterAggregate(aggregate);
    // De appliedEvents nog effectief handlen
    print('============= De appliedEvents nog effectief handlen');
    await _handleEventsAppliedByCommand(aggregate);

  }

  /// Load an aggregate by id from the cache...
  /// This is actually a DTO wrapped around a private reference to the actual aggregate,
  /// so we are sure that any changes to the aggregate immediately reflect the DTO
  T getCachedAggregateDtoById<T extends AggregateDto>(AggregateId aggregateId) {
    return AggregateDtoFactory.create(_aggregateCache.get(aggregateId));
  }

  void evictAggregateFromCache(AggregateId aggregateId) {
    _aggregateCache.purge(aggregateId);
  }

  /// Enable caching for a given aggregate
  /// TODO: try to make private?? now also used in tests, but maybe tests don't need to know about this?
  Future<void> loadAndAddAggregateToCache(AggregateId aggregateId, Type aggregateType) async {
    if (!_aggregateCache.contains(aggregateId)) {
      final aggregate = await _loadHydratedAggregate(aggregateType, aggregateId);
      _aggregateCache.store(aggregate);
    }
  }

  bool isRegistered(AggregateId aggregateId) {
    return _registeredAggregates.containsKey(aggregateId);
  }

  Future<void> refreshCache(Type aggregateType, AggregateId aggregateId) async {
    _aggregateCache.store(await _loadHydratedAggregate(aggregateType, aggregateId));
  }

  /// All events that have been applied by the command handler, should be handled and published remotely
  Future<void> _handleEventsAppliedByCommand(Aggregate aggregate) async {
    final eventHandler = _getDomainEventHandlerFor(aggregate.runtimeType);
    final appliedDomainEvents = <DomainEvent>{};
    for (var event in aggregate.pendingEvents) {
      final sequence = await _eventStore.nextSequenceForAggregate(aggregate.aggregateId);
      final domainEvent = _domainEventFactory.local(aggregate.aggregateId, sequence, event);
      _logger.d('Handling event triggered by command: $domainEvent');
      try {
        eventHandler.handle(aggregate, domainEvent);
        appliedDomainEvents.add(domainEvent);
      } on Exception catch (exception) {
        // In case something should go wrong, we'll need to roll back everything!
        // This means any previously applied events as well
        // We need this because of "atomicity"!
        // We cannot have a command of which only half its applied events are actually handled and stored
        // So we'll just invalidate the cached aggregate, the events are stored after all events have been applied successfully
        aggregate = await _loadHydratedAggregate(aggregate.runtimeType, aggregate.aggregateId);
        throw exception;
      }
    }
    // Actually store the events now that we know they've all been applied properly
    for (var domainEvent in appliedDomainEvents) {
      try {
        await _eventStore.storeDomainEvent(domainEvent);
        _remoteEventPublisher?.publishDomainEvent(domainEvent);
      } on Exception catch (exception) {
        print('========== prbleem tijdens command.... ABORT ALL THE THINGs!');
        // TODO: okay, hier zit de meat van het probleem! we moeten zien dat het commando geweigerd wordt indien hier iets foutloopt??
        // damn...
        // TODO: testen + afhandelen!
        _logger.e(exception);
        throw exception;
      }
    }
    aggregate.pendingEvents.clear();
  }

  /// Call the correct command handler for the given command,
  /// and return the relevant aggregate.
  Future<Aggregate> _handleCommand(dynamic command) async {
    AggregateId aggregateId = _extractAggregateId(command);
    // The aggregate on which the command should be applied.
    // We'll use the registered command handler(s) to create a new Aggregate instances based on the given command
    Aggregate aggregate;
    final commandHandler = _getCommandHandlerFor(command);
    if (commandHandler.isConstructorCommand(command)) {
      // First make sure no Aggregate for the given AggregateId exists already
      // For now only in local event manager, but maybe we should check the remote as well?
      // Or somehow allow for updating the aggregateId. The chances of accidentally using duplicate aggregateId's are very slim!
      // When it's done on purpose, tough luck then...
      if (await _eventStore.hasEventsForAggregate(aggregateId)) {
        throw AggregateIdAlreadyExistsException(aggregateId);
      }
      aggregate = commandHandler.handleConstructorCommand(command);
    } else {
      if (_aggregateCache.contains(aggregateId)) {
        aggregate = _aggregateCache.get(aggregateId);
      } else {
        // When not yet stored in cache, request events from local event manager and apply them...
        aggregate = commandHandler.newInstance(aggregateId);
        await _eventStore.getDomainEvents(aggregateId: aggregateId).forEach((event) {
          aggregate.apply(event.payload);
        });
      }
      print("----------- handling commando... ");
      commandHandler.handle(aggregate, command);
      print("----------- DONE handling commando... what about the events... ");
    }
    return aggregate;
  }

  /// Make sure the aggregate is properly cached and registered.
  /// We do this because aggregates for which we're handling commands are pretty likely to be "commanded" again.
  Future<void> _cacheAndRegisterAggregate(Aggregate aggregate) async {
    _aggregateCache.store(aggregate);
    registerAggregate(aggregate.aggregateId, aggregate.runtimeType);
    await loadAndAddAggregateToCache(aggregate.aggregateId, aggregate.runtimeType);
  }

  /// Basic command validation
  /// Make sure the aggregateId is available.
  void _validateCommand(command) {
    try {
      // ignore: unnecessary_statements
      command.aggregateId;
      // ignore: avoid_catching_errors
    } on NoSuchMethodError {
      throw InvalidCommandException(command, 'aggregateId is required');
    }
    if (command.aggregateId == null || command.aggregateId.toString().isEmpty) {
      throw InvalidCommandException(command, 'aggregateId is required');
    }
  }

  AggregateId _extractAggregateId(command) {
    final aggregateId = AggregateId.of(command.aggregateId as String);
    return aggregateId;
  }

  /// Handle the given DomainEvent using the wired (generated) EventHandler.
  /// We don't pass the aggregate, each event should contain the "aggregateId" and "aggregateType".
  Future<void> _handleRemoteEvent(DomainEvent domainEvent) async {
    // Kijken of we de aggregate van dit event in't oog houden of niet...
    final aggregateId = domainEvent.aggregateId;
    if (!_registeredAggregates.containsKey(aggregateId)) {
      _logger.w('Ignoring $domainEvent for unregistered aggregate $aggregateId');
      return;
    }
    // If the aggregate is in our cache, we'll immediately apply the event
    Aggregate aggregate;
    if (_aggregateCache.contains(aggregateId)) {
      // Een lege, default instance aanmaken en verdere events afhandelen...
      aggregate = _aggregateCache.get(aggregateId);
      // TODO: check 1: is aggregate up-to-date (should be, but you never know..)
      // TODO: check 2: pull events from remote event manager?? (probably not something we really want to do)
    } else {
      // Load the (hydrated) aggregate and store it in cache.
      // TODO: TO TEST so this means that we'll automatically cache every Aggregate that we've registered!?
      //  NOT according to 'Handle regular event for registered, non-cached aggregateId' ...
      aggregate = await _loadHydratedAggregate(domainEvent.aggregateType, aggregateId);
      _aggregateCache.store(aggregate);
    }
    // Load the matching event handler and apply the event!
    final eventHandler = _getDomainEventHandlerFor(aggregate.runtimeType);
    _logger.d('Handling event triggered by eventmanager (remote) stream: $domainEvent');
    eventHandler.handle(aggregate, domainEvent);
  }

  /// Loads a fully (re)hydrated aggregate based on all currently stored events
  Future<T> _loadHydratedAggregate<T extends Aggregate>(Type runtimeType, AggregateId aggregateId) async {
    final eventHandler = _getDomainEventHandlerFor(runtimeType);
    // Nieuwe instance maken
    final aggregate = eventHandler.newInstance(aggregateId);
    // Alle events die we al hebben eerst nog apply'en!
    _eventStore.getDomainEvents(aggregateId: aggregateId).forEach((DomainEvent domainEvent) {
      _logger.d('Handling event triggered by hydration: $domainEvent');
      eventHandler.handle(aggregate, domainEvent);
    });
    return aggregate as T;
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
  /// There can only be one, if we want to communicate events across Aggregates,
  /// we'll have to make use of IntegrationEvents...
  EventHandler _getDomainEventHandlerFor(Type runtimeType) {
    return _eventHandlers.where((EventHandler handler) => handler.forType(runtimeType)).first;
  }
}
