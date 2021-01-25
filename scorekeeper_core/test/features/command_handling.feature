Feature: Handling of commands issued to the Scorekeeper instance
  The Scorekeeper instance can be wired to handle commands that will lead to events that are to be stored and applied to a locally cached state.
  In these scenario's we'll test the wiring of command handlers, the caching of the aggregates and the local storage of the related domain events.


