Library used for code generation for custom domain libraries within the Scorekeeper ecosystem.

## Usage

Your custom domain should have a dev_dependency on the scorekeeper_codegen package.
When you've defined your domain's aggregate(s), commands and events, you can generate the required 
`CommandHandler` and `EventHandler` implementations that are used by the `Scorekeeper` instance.

### Domain classes
```
@aggregate
class Scorable extends Aggregate {
    late String name;

    @commandHandler
    Scorable.command(CreateScorable command) : super(AggregateId.of(command.aggregateId)) {
        final event = ScorableCreated()
            ..aggregateId = command.aggregateId
            ..name = command.name;
        apply(event);
    }
    
    @eventHandler
        void handleScorableCreated(ScorableCreated event) {
        name = event.name;
    }
   
    /// Check if given command is allowed.
    /// We separate this from the commandHandler, 
    CommandAllowance isAllowed(dynamic command) {
        switch (command.runtimeType) {
            default:
            return CommandAllowance(command, true, 'Allowed by default');
        }
    }
}

/// Command to create a new Scorable
class CreateScorable {
    late String aggregateId;
    late String name;
}

/// Event for a newly created Scorable
class ScorableCreated {
    late String aggregateId;
    late String name;
}
```

### Building
In order to build the required Command- and EventHandlers, execute:

``` pub run build_runner build ```





TODO:
 - deze flow wordt aangepast!
    1. protoc generate dart classes from commands and events
        -> kunnen we die laten "parten"??
    2. scorekeeper_codegen "pub run build_runner build", waarbij generated event/command classes gebruikt worden
        -> moeten we aggregates ook serializable maken?
            -> zou handig zijn voor snapshots...
            -> maar dan moet aggregate wel een wrapper rond een aparte "state" worden...
                -> ipv "late String name" => "final ScorableState state;" waarin dan gewerkt kan worden met de gekende properties
                -> en dan kan een aggregate gemakkelijk op basis van "state" gecreëerd worden...
                -> moet die ni obv events altijd aangemaakt worden? => NOPE: snapshots!
        -> zullen beginnen met events & commands
       