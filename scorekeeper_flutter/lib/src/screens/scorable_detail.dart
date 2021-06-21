import 'package:flutter/material.dart';
import 'package:scorekeeper_domain_scorable/scorable.dart';

import '../services/service.dart';

class ScorableDetailPage extends StatefulWidget {
  final MuurkeKlopNDownDto scorable;

  final ScorekeeperService scorekeeperService;

  ScorableDetailPage(this.scorekeeperService, this.scorable);

  @override
  _ScorableDetailPageState createState() => _ScorableDetailPageState(scorekeeperService, scorable);
}

class _ScorableDetailPageState extends State<ScorableDetailPage> {
  final ScorekeeperService scorekeeperService;

  final MuurkeKlopNDownDto scorable;

  _ScorableDetailPageState(this.scorekeeperService, this.scorable);

  /// Show the dialog to input a new Participant
  void _showAddParticipantDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _AddParticipantDialog(_addParticipant));
  }

  /// Actually add the participant
  void _addParticipant(String name) {
    scorekeeperService.addParticipantToScorable(scorable.aggregateId, name);
    setState(() {
      // We don't need to set anything explicitly, we know our commands are handled synchronously
    });
  }

  /// Add a round
  void _addRound() {
    scorekeeperService.addRoundToScorable(scorable.aggregateId);
    setState(() {
      // We don't need to set anything explicitly, we know our commands are handled synchronously
    });
  }

  /// Send an arbitrary command
  void _sendCommand(command) {
    scorekeeperService.sendCommand(command);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(scorable.name),
      ),
      body: Table(
        children: scorableParticipantList(scorable),
        columnWidths: scorableTableColWidth(scorable),
        defaultColumnWidth: const IntrinsicColumnWidth(),
      ),
    );
  }

  /// By default we got the "Participant" column, ROUNDS + 1 Round columns, Total column
  /// This map will only provide column widths for the "round" columns
  Map<int, TableColumnWidth> scorableTableColWidth(MuurkeKlopNDownDto scorable) {
    final map = <int, TableColumnWidth>{};
    for (var roundIndex = 0; roundIndex < scorable.rounds.length; roundIndex++) {
      map[roundIndex + 1] = const FixedColumnWidth(100.0);
    }
    return map;
  }

  /// create a list of table rows used
  List<TableRow> scorableParticipantList(MuurkeKlopNDownDto scorable) {
    final rowList = List<TableRow>.empty(growable: true)
      // Header row
      ..add(TableRow(children: [
        TableCell(child: _ParticipantTableContainer(const Text('Player'))),
        ...roundHeadTableCells(),
        TableCell(child: _ParticipantTableContainer(const Text('Total')))
      ]));
    // Body row
    for (final participant in scorable.participants) {
      rowList.add(TableRow(children: [
        TableCell(child: _ParticipantTableContainer(Text(participant.participantName))),
        ...participantRoundBody(participant),
        TableCell(child: _ParticipantTableContainer(const Text('Total')))
      ]));
    }
    // Footer row
    rowList.add(TableRow(children: [
      TableCell(
          child: _ParticipantTableContainer(TextButton(
        onPressed: () => _showAddParticipantDialog(context),
        // tooltip: 'Add new Participant',
        child: const Icon(Icons.add),
      ))),
      ..._roundsFooter(),
      TableCell(child: _ParticipantTableContainer(
          // TODO: button van maken gebaseerd op allowance "FinishScorable" / "Restart Scorable"
          const Text('Spel afronden')))
    ]));

    return rowList;
  }

  /// Return TableCell
  List<TableCell> roundHeadTableCells() {
    if (scorable.rounds.isEmpty) {
      return List.of([TableCell(child: _ParticipantTableContainer(const Text('Rounds')))]);
    }
    return scorable.rounds.values
        .map((round) => TableCell(child: _ParticipantTableContainer(Text('Round ${round.roundIndex + 1}'))))
        .toList(growable: true)
          ..add(TableCell(child: _ParticipantTableContainer(const Text(''))));
  }

  List<TableCell> participantRoundBody(Participant participant) {
    if (scorable.rounds.isEmpty) {
      return List.of([TableCell(child: _ParticipantTableContainer(const Text('')))]);
    }
    return scorable.rounds.values
        .map((round) => TableCell(child: _ParticipantTableContainer(const Text('Strike out ?'))))
        .toList(growable: true)
          ..add(TableCell(child: _ParticipantTableContainer(const Text('-'))));
  }

  List<TableCell> _roundsFooter() {
    if (scorable.rounds.isEmpty) {
      return List.of([
        TableCell(
            child: _ParticipantTableContainer(TextButton(
          onPressed: _addRound,
          // tooltip: 'Add new Round',
          child: const Icon(Icons.add),
        )))
      ]);
    }
    return scorable.rounds.values
        .map(_roundAllowanceOptions)
        .toList(growable: true)
          // Add a column to add an additional round
          ..add(TableCell(
              child: _ParticipantTableContainer(TextButton(
            onPressed: _addRound,
            // tooltip: 'Add new Round',
            child: const Icon(Icons.add),
          ))));
  }

  TableCell _roundAllowanceOptions(MuurkeKlopNDownRound round) {
    // First list all commands we are considering here
    final commands = [
      StartRound()
        ..scorableId = scorable.aggregateId.id
        ..roundIndex = round.roundIndex,
      FinishRound()
        ..scorableId = scorable.aggregateId.id
        ..roundIndex = round.roundIndex
    ];

    // Then check whether or not they're allowed

    // Finally display the allowed commands
    final icons = Wrap(children: [
      ...commands.map((command) => TextButton(
          onPressed: () => _sendCommand(command),
          // TODO: Icon moet nog dynamisch bepaald worden!
          child: Icon(Icons.play_arrow, semanticLabel: command.runtimeType.toString())))
    ]);

    return TableCell(child: _ParticipantTableContainer(icons));
  }
}

/// The dialog for adding a new Participant to the Scorable
class _AddParticipantDialog extends StatelessWidget {
  final void Function(String name) callback;

  _AddParticipantDialog(this.callback);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add new Player'),
      content: _AddParticipantForm(callback),
      // actions: [
      //   FlatButton(
      //       onPressed: () => callback('NAME'),
      //       child: const Text('Add')
      //   )
      // ],
    );
  }
}

class _AddParticipantForm extends StatefulWidget {
  final void Function(String name) callback;

  _AddParticipantForm(this.callback);

  @override
  State<StatefulWidget> createState() {
    return _AddParticipantFormState(callback);
  }
}

class _AddParticipantFormState extends State<_AddParticipantForm> {
  // Create a global key that uniquely identifies the Form widget and allows validation of the form.
  final _formKey = GlobalKey<FormState>();

  final void Function(String name) callback;

  _AddParticipantFormState(this.callback);

  final nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (null != _formKey.currentState && _formKey.currentState!.validate()) {
      callback(nameController.text);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: const BoxConstraints(minHeight: 100, minWidth: double.infinity, maxHeight: 300),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              autofocus: true,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'The name of the player',
              ),
              validator: (value) {
                if (null != value && value.isEmpty) {
                  return 'Please enter a name for the player';
                }
                return null;
              },
              controller: nameController,
              onFieldSubmitted: (name) => _submitForm(),
            ),
            const Spacer(),
            ElevatedButton(
                onPressed: _submitForm,
                child: Container(
                  child: const Text('Add player'),
                ))
          ]),
        ));
  }
}

class _ParticipantTableContainer extends StatelessWidget {
  final Widget content;

  _ParticipantTableContainer(this.content);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: content,
    );
  }
}
