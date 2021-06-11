An example domain implementation to be used within the Scorekeeper application.

Make sure to build it first using the following command:

``` pub run build_runner build ```

## Functionality
Builds a couple of files required to use the domain.

In case it is your first build, you'll need to run the following command:

`` pub run build_runner build ``

Once that is out of the way, you can use your IDE.




### Input
One ``.dart`` file per domain to be used.
This example domain depends on the ``scorekeeper_domain`` package,
which contains a `build.yaml` file in which all required generators are defined.
These generators will generate the necessary classes for the domain to be used within the Scorekeeper ecosystem.

In your domain package, each ``[domain].dart`` file will be used to generate a set of files.

### Output
1. one single `.f.dart` file containing the factory for all defined aggregate DTO's
2. one `.d.dart` file per domain containing the DTO's to be used
3. one `.h.dart` file per domain containing the command and event handlers



# Issues!
- extra generator is not recognized for some reason.
  At the moment, we have 2 generators, and want to create a 3rd one.
  However, this new generator is not being triggered.
    - Solution:
        1. clear the ``.dart_tool`` folder (contains cached files)
        2. run the ``pub get`` command (since we've probably changed the ``scorekeeper_domain`` dependency)
        3. run the ``pub run build_runner build`` command to generate sources anew
            - select the "delete" option when prompted
    - The old generators were being cached, so the new one wouldn't be picked up...
