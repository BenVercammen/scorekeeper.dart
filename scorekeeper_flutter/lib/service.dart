
import 'package:ordered_set/ordered_set.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:uuid/uuid.dart';

/// An API implementation designed specifically for the UI
/// TODO: deze mag mss toch nog in een aparte package? Is een API layer bovenop de commands en events...
///   Op die manier kunnen we die commands/events van de UI afschermen
///   Maar dan kunnen we wel naar onze "allowances" fluiten, niet?
///     => gewoon aan de service vragen of die knop/action toegestaan is of niet he...
///   Is weer een extra tussenlaag....
class ScorekeeperService {

  // The actual Scorekeeper application (write model)
  final Scorekeeper _scorekeeper;

  ScorekeeperService(this._scorekeeper);

  /// Add a new Scorable
  MuurkeKlopNDownDto createNewScorable(String scorableName) {
    final aggregateId = AggregateId.random();
    final command = CreateScorable()
      ..aggregateId = aggregateId.id
      ..name = 'New Scorable';
    _scorekeeper.handleCommand(command);
    return _scorekeeper.getCachedAggregateDtoById<MuurkeKlopNDownDto>(aggregateId);
  }

  /// Add a newly created Participant to the Scorable
  void addParticipantToScorable(AggregateId aggregateId, String participantName) {
    final participant = Participant(Uuid().v4(), participantName);
    final command = AddParticipant()
      ..participant = participant
      ..aggregateId = aggregateId.id;
    _scorekeeper.handleCommand(command);
  }

  /// Add a new Round to the Scorable
  void addRoundToScorable(AggregateId aggregateId) {
    final command = AddRound()
      ..aggregateId = aggregateId.id;
    _scorekeeper.handleCommand(command);
  }

  /// Load Scorables ordered descending by last modified date
  OrderedSet<MuurkeKlopNDownDto> loadScorables(int page, int pageSize) {
    final allDtos = OrderedSet<MuurkeKlopNDownDto>((AggregateDto dto1, AggregateDto dto2) {
      return dto1.lastModified.millisecondsSinceEpoch - dto2.lastModified.millisecondsSinceEpoch;
    })
      ..addAll(_scorekeeper.registeredAggregateIds.map(_scorekeeper.getCachedAggregateDtoById));
    var resultDtos = OrderedSet<MuurkeKlopNDownDto>((AggregateDto dto1, AggregateDto dto2) {
      return dto1.lastModified.millisecondsSinceEpoch - dto2.lastModified.millisecondsSinceEpoch;
    });
    for (var i = 0; i < allDtos.length; i++) {
      if (i >= (page * pageSize) && i < ((page + 1) * pageSize )) {
        resultDtos.add(allDtos.elementAt(i));
      }
    }
    return resultDtos;
  }

  /// Send an arbitrary command to the Scorekeeper instance.
  /// TODO: is this something we actually want to be doing?
  /// Something to think about...
  void sendCommand(command) {
    _scorekeeper.handleCommand(command);
  }

}