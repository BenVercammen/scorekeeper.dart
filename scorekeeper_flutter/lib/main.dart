import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:scorekeeper_core/scorekeeper.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:scorekeeper_example_domain/example.dart';
import 'package:uuid/uuid.dart';

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

  runApp(MyApp(scorekeeperService));
}

class MyApp extends StatelessWidget {

  final ScorekeeperService _scorekeeperService;

  MyApp(this._scorekeeperService);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scorekeeper Demo Application',
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
      home: ScorableOverviewPage(title: 'Scorekeeper Demo Home Page', scorekeeperService: _scorekeeperService),
    );
  }
}

/// An API implementation designed specifically for the UI
/// TODO: deze mag mss toch nog in een aparte package? Is een API layer bovenop de commands en events...
///   Op die manier kunnen we die commands/events van de UI afschermen
///   Maar dan kunnen we wel naar onze "allowances" fluiten, niet?
///     => gewoon aan de service vragen of die knop/action toegestaan is of niet he...
///   Is weer een extra tussenlaag....
class ScorekeeperService {

  // The actual Scorekeeper application
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

  _ScorableOverviewPageState(this._scorekeeperService);

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
