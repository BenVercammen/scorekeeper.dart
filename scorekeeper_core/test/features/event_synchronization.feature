Feature: Event synchronization between multiple Scorekeeper instances
  The Scorekeeper instance has its own local event store, where it will keep track of events for locally registered aggregates.
  These events can be shared with remote instance(s) using the RemoteEventPublisher.
  On the other hand, the Scorekeeper instance can also receive events from remote instances using the RemoteEventListener.
  These remote events can of course be a cause of conflicts, as they may duplicate or supersede local events,
  thus resulting in a possibly different state.
  It is the handling of those conflicts that we are going to define in these scenario's.
