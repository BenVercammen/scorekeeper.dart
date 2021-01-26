import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_example_domain/example.dart';

import 'main.dart';

class ScorableDetailPage extends StatefulWidget {

  final ScorableDto scorable;

  final ScorekeeperService scorekeeperService;

  ScorableDetailPage(this.scorekeeperService, this.scorable);

  @override
  _ScorableDetailPageState createState() => _ScorableDetailPageState(scorekeeperService, scorable);

}

class _ScorableDetailPageState extends State<ScorableDetailPage> {

  final ScorekeeperService scorekeeperService;

  final ScorableDto scorable;

  _ScorableDetailPageState(this.scorekeeperService, this.scorable);

  // TODO: ook nog wel een probleem met het exposen van die Participant en Scorable objecten... Ik zou eigenlijk enkel DTO's naar buiten toe willen exposen!
  // List<Participant> participants = List.empty(growable: true);

  void _addParticipant() {
    scorekeeperService.addParticipantToScorable(scorable.aggregateId, 'Player One');
    setState(() {
      // participants = scorable.participants;
      // We don't need to set anything explicitly, we know our commands are handled synchronously
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(scorable.name),
      ),
      body: ListView.builder(
          itemCount: scorable.participants.length,
          itemBuilder: (BuildContext context, int index) {
            return Text('Participant $index (${scorable.participants.elementAt(index)})');
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addParticipant,
        tooltip: 'Add new Participant',
        child: const Icon(Icons.add),
      ),
    );
  }


}