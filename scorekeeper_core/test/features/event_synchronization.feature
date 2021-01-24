Feature: Event synchronization between multiple Scorekeeper instances
  The Scorekeeper instance is responsible for
  - handling commands and the resulting events
  - storing locally created events in the local event store (storeAndPublishRemote)
  - publishing locally created events to the remote event listener(s) (storeAndPublishRemote)
  - storing remotely created events in the local event store (storeAndPublishLocal)
  - publishing remotely created events to the local event handlers (storeAndPublishLocal)


  Scenario: Events emitted by locally handled commands should be stored locally and published remotely
    Given the following DomainEvents have already been stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    # TODO: probleem is nu dat we weer van "EventManager" naar "Scorekeeper" zijn geschoven...
    # TODO: use something like a command instead of events (we cannot "trigger" local events...)
    When the following DomainEvents are to be stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    Then the following DomainEvents should be stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    And the following DomainEvents should be published remotely
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    And a message should be logged stating "ignored duplicate event"


  # This should not be possible if the Scorekeeper is working properly, but still...
  Scenario: Duplicate events should not be stored
    Given the following DomainEvents have already been stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    When the following DomainEvents are to be stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    Then the following DomainEvents should be stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    And no DomainEvents should be published remotely
    And a message should be logged stating "ignored duplicate event"


  # TODO: Remotely received events should be stored and published locally (but not remotely)

  # TODO: Locally received events should be stored locally and published remotely


  Scenario: EventManager receiving duplicate event from remote event source
    Given the following DomainEvents have already been stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    When the following DomainEvents are received remotely
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    Then the following DomainEvents should be stored locally
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    And a message should be logged stating "ignored duplicate event"




  #  | from   | to    | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |
  #  | local  | local | true                        | true                    | true                     | local ?= remote payload |
  #  | from | to | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |
  #  | from | to | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |
  #  | from | to | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |
  #  | from | to | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |
  #  | from | to | local ?= remote aggregateId | local ?= remote eventId | local ?= remote sequence | local ?= remote payload |



  # Event was received but never acknowledged
  # Event was received but acknowledgement didn't come through
  # Event was not received
  # Event was not sent

  # remote instance offline?
  # Event cannot get lost!?
