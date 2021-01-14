
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';


void main() {

  group('EventId', () {

    test('Test local constructor', () {
      EventId eventId = EventId.local(null);
      expect(eventId.localId, equals(eventId.originId));
      expect(eventId.prevOriginId, equals(null));
    });

    test('Test origin constructor', () {
      EventId eventId = EventId.origin(EventId.local(null));
      expect(eventId.localId, isNot(equals(eventId.originId)));
    });

    // TODO: veel meer logica nu nodig als we zo vrij met events willen omspringen...

  });



  /// TODO: EventManager ook goed testen, zien dat events en aggregates apart gecleared/gemanaged moeten worden!


  group('EventHandlerInMemoryImpl', () {

    group('storeAndPublish', () {

      test('happy flow', () {
        /// TODO:
        ///  - storeAndPublish: zien dat het event effectief gepersisteerd wordt + op de stream terecht komt
        ///     - weliswaar enkel als het om een aggregateId gaat waarop we geregistreerd zijn!
        ///  - getEventsForAggregate: zien dat we alle events voor een aggregate kunnen opvragen
        ///  - (un)registerAggregateId(s):
      });

    });

  });
}


