import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:scorekeeper_flutter/service.dart';

import 'scorable_detail.dart';

void main() {

  // Create an instance
  final scorekeeper = Scorekeeper(
      eventStore: EventStoreInMemoryImpl(),
      aggregateCache: AggregateCacheInMemoryImpl())
  // Register the command and event handlers for the relevant domain
    ..registerCommandHandler(MuurkeKlopNDownCommandHandler())
    ..registerEventHandler(MuurkeKlopNDownEventHandler());

  final scorekeeperService = ScorekeeperService(scorekeeper);

  // Default data for testing purposes
  final defaultScorable = scorekeeperService.createNewScorable('Default Game');
  final aggregateId = defaultScorable.aggregateId;
  scorekeeperService
      ..addParticipantToScorable(aggregateId, 'Player 1')
      ..addParticipantToScorable(aggregateId, 'Player 2')
      ..addParticipantToScorable(aggregateId, 'Player 3')
      ..addRoundToScorable(aggregateId)
      ..addRoundToScorable(aggregateId)
      ..addRoundToScorable(aggregateId)
      ..addRoundToScorable(aggregateId)
      ..addRoundToScorable(aggregateId);

  runApp(ScorableApp(scorekeeperService));
}

class ScorableApp extends StatelessWidget {

  final ScorekeeperService _scorekeeperService;

  ScorableApp(this._scorekeeperService);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scorekeeper Demo Application - Muurke Klop',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: ScorableOverviewPage(title: 'Scorekeeper Demo Application - Muurke Klop', scorekeeperService: _scorekeeperService),
    );
  }
}


class ScorableOverviewPage extends StatefulWidget {

  final String title;

  final ScorekeeperService scorekeeperService;

  ScorableOverviewPage({Key key, this.title, this.scorekeeperService}) : super(key: key);

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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:

      ListView.builder(
          itemCount: scorables.values.length,
          itemBuilder: scorableItemBuilder
      ),

      // Center(
      //   // Center is a layout widget. It takes a single child and positions it
      //   // in the middle of the parent.
      //   child: Column(
      //     // Column is also a layout widget. It takes a list of children and
      //     // arranges them vertically. By default, it sizes itself to fit its
      //     // children horizontally, and tries to be as tall as its parent.
      //     //
      //     // Invoke "debug painting" (press "p" in the console, choose the
      //     // "Toggle Debug Paint" action from the Flutter Inspector in Android
      //     // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
      //     // to see the wireframe for each widget.
      //     //
      //     // Column has various properties to control how it sizes itself and
      //     // how it positions its children. Here we use mainAxisAlignment to
      //     // center the children vertically; the main axis here is the vertical
      //     // axis because Columns are vertical (the cross axis would be
      //     // horizontal).
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Text(
      //         'You have created this many scorables:',
      //       ),
      //       Text(
      //         '${scorables.length}',
      //         style: Theme.of(context).textTheme.headline4,
      //       ),
      //     ],
      //   ),
      // ),
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
