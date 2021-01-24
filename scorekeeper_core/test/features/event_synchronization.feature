Feature: Event synchronization

  Scenario: Event conflict management
    Given local EventManager has DomainEvents
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    When local EventManager receives DomainEvents
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |
    Then local EventManager should have the following DomainEvents
      | eventUuid | eventSequence | eventTimestamp           | aggregateId | payload.type     | payload.property1 |
      | 1         | 0             | 2021-01-23T13:00:00.000Z | 100         | ConstructorEvent | value 1           |


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
