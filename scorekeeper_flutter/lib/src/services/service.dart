import 'package:logger/logger.dart';
import 'package:ordered_set/ordered_set.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_core/scorekeeper_test_util.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';
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

  late Logger _logger;

  ScorekeeperService(this._scorekeeper, [Logger? logger]) {
    _logger = logger ?? Logger();
  }

  /// Add a new Scorable
  Future<MuurkeKlopNDownDto> createNewScorable(String scorableName, Type scorableType) async {
    final aggregateId = AggregateId.random(scorableType);
    final command = CreateScorable()
      ..scorableId = aggregateId.id
      ..name = scorableName;
    _logger.d('START handle command from service (createNewScorable)');
    await _scorekeeper.handleCommand(command);
    _logger.d('DONE handle command from service (createNewScorable)');
    // Nu gaan we die uit de cache halen, maar blijkbaar zit em er nog niet volledig geladen in??
    return await _scorekeeper.getCachedAggregateDtoById<MuurkeKlopNDownDto>(aggregateId);
  }

  /// Add a newly created Participant to the Scorable
  Future<void> addParticipantToScorable(AggregateId aggregateId, String participantName) async {
    var scorable = await _scorekeeper.getCachedAggregateDtoById<MuurkeKlopNDownDto>(aggregateId);
    final participant = Participant()..participantId = Uuid().v4()..participantName = participantName;
    final command = AddParticipant()
      ..participant = participant
      ..scorableId = aggregateId.id;
    _logger.d('START handle command from service (addParticipantToScorable)');
    await _scorekeeper.handleCommand(command);
    _logger.d('DONE handle command from service (addParticipantToScorable)');
  }

  /// Add a new Round to the Scorable
  Future<void> addRoundToScorable(AggregateId aggregateId) async {
    final command = AddRound()..scorableId = aggregateId.id;
    _logger.d('START handle command from service (addRoundToScorable)');
    await _scorekeeper.handleCommand(command);
    _logger.d('DONE handle command from service (addRoundToScorable)');
  }

  /// Load Scorables ordered descending by last modified date
  /// TODO: for now it's loading ALL (stored/registered/cached/...) aggregates, this needs to be fixed!
  Future<OrderedSet<MuurkeKlopNDownDto>> loadScorables(int page, int pageSize) async {
    _logger.d('START loadScorables (TODO: is this done too often?)');
    final registeredAggregateIds = await _scorekeeper.registeredAggregateIds.toSet();
    final cachedAggregates = <MuurkeKlopNDownDto>{};
    for (final aggregateId in registeredAggregateIds) {
      cachedAggregates.add(await _scorekeeper.getCachedAggregateDtoById(aggregateId));
    }
    final allDtos = OrderedSet<MuurkeKlopNDownDto>((AggregateDto dto1, AggregateDto dto2) {
      if (null == dto2.lastModified && null == dto1.lastModified) {
        return 0;
      }
      if (null == dto2.lastModified) {
        return -1;
      }
      if (null == dto1.lastModified) {
        return 1;
      }
      return dto2.lastModified!.millisecondsSinceEpoch - dto1.lastModified!.millisecondsSinceEpoch;
    })
      ..addAll(cachedAggregates);
    final resultDtos = OrderedSet<MuurkeKlopNDownDto>((AggregateDto dto1, AggregateDto dto2) {
      return dto2.lastModified!.millisecondsSinceEpoch - dto1.lastModified!.millisecondsSinceEpoch;
    });
    for (var i = 0; i < allDtos.length; i++) {
      if (i >= (page * pageSize) && i < ((page + 1) * pageSize)) {
        resultDtos.add(allDtos.elementAt(i));
      }
    }
    _logger.d('DONE loadScorables');
    return resultDtos;
  }

  /// Send an arbitrary command to the Scorekeeper instance.
  /// TODO: is this something we actually want to be doing?
  /// Something to think about...
  Future<void> sendCommand(command) async {
    _logger.d('START handle command from service (sendCommand)');
    await _scorekeeper.handleCommand(command);
    _logger.d('DONE handle command from service (sendCommand)');
  }
}
