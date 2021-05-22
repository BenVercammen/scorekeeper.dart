Feature: Event synchronization between multiple Scorekeeper instances
  The Scorekeeper instance has its own local event store, where it will keep track of events for locally registered aggregates.
  These events can be shared with remote instance(s) using the RemoteEventPublisher.
  On the other hand, the Scorekeeper instance can also receive events from remote instances using the RemoteEventListener.
  These remote events can of course be a cause of conflicts, as they may duplicate or supersede local events,
  thus resulting in a possibly different state.
  It is the handling of those conflicts that we are going to define in these scenario's.


Scenario: The remote event to be received is a nice follow-up of the local event log (no conflict)
  # event is received, stored and processed locally without any issues

Scenario: The local event to be emitted is a nice follow-up of the remote event log (no conflict)
  # event is emitted, the remote event store will accept it without any issues
    # or maybe emit some sort of "accepted" event?
    # or remote event store will just emit all received events again, it is up to the local instance to take this as an "acknowledgement"?

Scenario: The local event to be emitted conflicts with the remote event log (sequence, ...)
  # TODO: event is emitted anyway, remote event store will provide a "conflict event"...
  # None of the subsequent events will be accepted by the remote event store untill the conflict has been resolved


Scenario: The conflicting event triggers new events??
  # is this possible? local events triggering extra events?
  #  -> last strike-out of a game -> game state changes...
  #     -> are state-changes reason to trigger a new event?
  #  -> last strike-out of last scorable of a round
  #     -> game == finished
  #     -> stage == finished
  #     -> next stage can be populated...
