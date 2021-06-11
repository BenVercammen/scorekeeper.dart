import 'package:ordered_set/ordered_set.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
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

  ScorekeeperService(this._scorekeeper);

  /// Add a new Scorable
  Future<MuurkeKlopNDownDto> createNewScorable(String scorableName) async {
    final aggregateId = AggregateId.random();
    final command = CreateScorable()
      ..aggregateId = aggregateId.id
      ..name = scorableName;
    await _scorekeeper.handleCommand(command);
    return await _scorekeeper.getCachedAggregateDtoById<MuurkeKlopNDownDto>(aggregateId);
  }

  /// Add a newly created Participant to the Scorable
  Future<void> addParticipantToScorable(AggregateId aggregateId, String participantName) async {
    final participant = Participant(const Uuid().v4(), participantName);
    final command = AddParticipant()
      ..participant = participant
      ..aggregateId = aggregateId.id;
    await _scorekeeper.handleCommand(command);
  }

  /// Add a new Round to the Scorable
  Future<void> addRoundToScorable(AggregateId aggregateId) async {
    final command = AddRound()..aggregateId = aggregateId.id;
    await _scorekeeper.handleCommand(command);
  }

  /// Load Scorables ordered descending by last modified date
  /// TODO: for now it's loading ALL aggregates, this needs to be fixed!
  Future<OrderedSet<MuurkeKlopNDownDto>> loadScorables(int page, int pageSize) async {
    final registeredAggregateIds = await _scorekeeper.registeredAggregateIds.toSet();
    final cachedAggregates = <MuurkeKlopNDownDto>{};
    registeredAggregateIds.forEach((a) async =>
      await cachedAggregates.add(await _scorekeeper.getCachedAggregateDtoById(a))
    );
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
    return resultDtos;
  }

  /// Send an arbitrary command to the Scorekeeper instance.
  /// TODO: is this something we actually want to be doing?
  /// Something to think about...
  Future<void> sendCommand(command) async {
    await _scorekeeper.handleCommand(command);
  }
}
