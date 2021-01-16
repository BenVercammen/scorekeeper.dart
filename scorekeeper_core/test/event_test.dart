
import 'package:scorekeeper_domain/core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';


void main() {

  group('DomainEventId', () {

    test('Test local constructor', () {
      final uuid = Uuid().v4();
      final eventId = DomainEventId.local(uuid, 0);
      expect(eventId.uuid, equals(uuid));
      expect(eventId.sequence, equals(0));
      expect(eventId.timestamp, isNotNull);
    });

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


