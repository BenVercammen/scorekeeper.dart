The core domain package for the scorekeeper application. 
This is the only dependency custom domains require (possibly along with the scorekeeper_codegen package).


## Code generation
We're using protocol buffers for our events/commands.
There are a few "common" message types that are shared across domains.
These are defined in the ``identifiers.proto`` file.

In order to generate the required files, use:

- ``pub global activate protoc_plugin`` (if not already installed)
- ``cd C:\Workspace\dart\scorekeeper\scorekeeper_domain``
- ``mkdir lib\src\generated`` (if not already exists)
- ``protoc --dart_out=lib/src/generated -Iprotos protos/events.proto``


## Protocol buffers and shared definitions
In order to make use of the shared "identifiers" messages,
we'll have to turn it into a "package" that can be imported?

At first, we just put the ``identifiers.proto`` file in ``scorekeeper_domain`` 
and then generate the other ``scorekeeper_domain_xxx`` packages.
However, in that case, there would be a conflict because of the generated ``AggregateId`` class
that would now be duplicated.

The solution is to turn this into a "package" that can be imported.
To do so:
 - import moet naar een package verwijzen?
    - momenteel wordt dat gewoon geimporteerd, ervan uit gaande dat alles in dezelfde folder gegenereerd zal worden
    - maar dat geeft dus conflicten als we dat over meerdere packages heen doen...
    => 1 gemeenschappelijke package maken?
        -> neen, want we kunnen niet zeggen dat die generated imports via "package" moeten gaan...
      
 => WRONG!
    -> even "packages" like this (eg: google/protobuf/datetime) will need to be generated over and over again
    -> the right solution would be to NOT expose the generated classes!
        -> some sort of mapping is required
        -> we need to cleanly separate them. 
        -> YES, they have the same definitions
        -> NO, they don't have the same classes/instances...
        => NOPE, we do need the events in our UI
            -> as well as Identifiers :/
 - So... now we have these event classes, but we should NEVER share them (ie: don't expose!)
 - The only common thing is the AggregateId!
    -> that's the whole point on which I'm stuck!
    -> the
   

Dus: ik heb een AggregateId class nodig, waarmee