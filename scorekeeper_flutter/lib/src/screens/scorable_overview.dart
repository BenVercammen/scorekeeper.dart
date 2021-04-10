import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

import '../services/service.dart';
import 'scorable_detail.dart';

class ScorableOverviewPage extends StatefulWidget {
  final String title;

  final ScorekeeperService scorekeeperService;

  ScorableOverviewPage({Key? key, required this.title, required this.scorekeeperService}) : super(key: key);

  @override
  _ScorableOverviewPageState createState() => _ScorableOverviewPageState(scorekeeperService);
}

class _ScorableOverviewPageState extends State<ScorableOverviewPage> {
  final ScorekeeperService _scorekeeperService;

  final Map<AggregateId, MuurkeKlopNDownDto> scorables = HashMap();

  _ScorableOverviewPageState(this._scorekeeperService) {
    // Load the 10 most recent scorables from the ScorableProjection
    scorables.addAll({for (var e in _scorekeeperService.loadScorables(0, 10)) e.aggregateId: e});
  }

  void _createNewScorable() {
    final scorable = _scorekeeperService.createNewScorable('New Scorable Name');
    setState(() {
      scorables.putIfAbsent(scorable.aggregateId, () => scorable);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(itemCount: scorables.values.length, itemBuilder: scorableItemBuilder),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewScorable,
        tooltip: 'Create new Scorable',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The Scorable ListView item builder
  Widget scorableItemBuilder(BuildContext context, int index) {
    final scorable = scorables.values.elementAt(index);
    return ListTile(
      title: Text('Scorable $index ($scorable)'),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) => ScorableDetailPage(_scorekeeperService, scorable)));
      },
    );
  }
}
