
 TODO: 
  - zelfde README als Scorable domaine


## Protobuf spike...
 - nu aan het proberen om in dit domain protobuf terug te incorporeren
 - dwz: events en commands genereren op basis van .proto files
    -> dit doen we om te kunnen serializen, belangrijk voor persistence (en evt transfer)
    -> belangrijk: alle metadata zit ook mee in event!
        -> TODO: kan mogelijks wel gestript worden in het domain... want daar willen we in principe niks van weten...
        -> in de DB worden de metadata velden ook nog wel eens apart in kolommen gestopt, om makkelijk te query'en, maar da's moor_store shit...
   
### Development
 - ``pub global activate protoc_plugin`` (if not already installed)
 - ``cd C:\Workspace\dart\scorekeeper\scorekeeper_domain_contest``
 - ``mkdir lib\src\generated`` (if not already exists)
 - ``protoc --dart_out=lib/src/generated -Iprotos protos/events.proto``


## Troubleshooting
 - ``Target of URI doesn't exist: 'package:protobuf/protobuf.dart'. (Documentation)``
    - Make sure your pubspec contains the `protobuf: 2.0.0` dependency
