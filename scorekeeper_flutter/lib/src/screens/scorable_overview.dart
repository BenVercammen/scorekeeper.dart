import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';

import '../services/service.dart';
import 'scorable_create.dart';
import 'scorable_detail.dart';

class ScorableOverviewPage extends StatefulWidget {
  final String title = 'Scorekeeper';

  final ScorekeeperService scorekeeperService;

  ScorableOverviewPage({Key? key, required this.scorekeeperService}) : super(key: key);

  @override
  _ScorableOverviewPageState createState() => _ScorableOverviewPageState(scorekeeperService);
}

class _ScorableOverviewPageState extends State<ScorableOverviewPage> {
  final ScorekeeperService _scorekeeperService;

  final Map<AggregateId, MuurkeKlopNDownDto> scorables = HashMap();

  int page = 0;

  int pageSize = 10;

  _ScorableOverviewPageState(this._scorekeeperService) {
    // Load the 10 most recent scorables from the ScorableProjection
    _loadScorables();
  }

  /// Load the scorables given the current page/pageSize values.
  void _loadScorables() {
    scorables.addAll({for (var e in _scorekeeperService.loadScorables(page, pageSize)) e.aggregateId: e});
  }

  void reloadState() {
    _loadScorables();
    setState(() {
    });
  }

  void _createNewScorableForm() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ScorableCreatePage(_scorekeeperService)))
        .whenComplete(reloadState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(itemCount: scorables.values.length, itemBuilder: scorableItemBuilder),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewScorableForm,
        tooltip: 'Create new Scorable',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The Scorable ListView item builder
  Widget scorableItemBuilder(BuildContext context, int index) {
    final scorable = scorables.values.elementAt(index);
    return ListTile(
      title: Text(scorable.name),
      subtitle: Text(scorable.lastModified!.toLocal().toIso8601String()),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) => ScorableDetailPage(_scorekeeperService, scorable)));
      },
    );
  }
}
