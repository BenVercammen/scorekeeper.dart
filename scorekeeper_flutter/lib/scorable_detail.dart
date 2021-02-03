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

  /// Show the dialog to input a new Participant
  void _showAddParticipantDialog(BuildContext context) {
    showDialog(context: context,
     builder: (context) => _AddParticipantDialog(_addParticipant)
    );
  }

  void _addParticipant(String name) {
    scorekeeperService.addParticipantToScorable(scorable.aggregateId, name);
    setState(() {
      // We don't need to set anything explicitly, we know our commands are handled synchronously
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(scorable.name),
      ),
      body: Table(
        children: scorableParticipantList(scorable)
      ),
    );
  }

  /// create a list of table rows used
  List<TableRow> scorableParticipantList(ScorableDto scorable) {
    final rowList = List<TableRow>.empty(growable: true);
    // Header row
    rowList.add(
        TableRow(
            children: [
              TableCell(
                child: _ParticipantTableContainer(const Text('Player'))
              ),
              TableCell(
                  child: _ParticipantTableContainer(const Text('Round ?'))
              ),
              TableCell(
                  child: _ParticipantTableContainer(const Text('Total'))
              ),
            ]
        )
    );
    // Body row
    for (Participant participant in scorable.participants) {
      rowList.add(
          TableRow(
              children: [
                TableCell(
                    child: _ParticipantTableContainer(Text(participant.name))
                ),
                TableCell(
                    child: _ParticipantTableContainer(const Text('Strike out?'))
                ),
                TableCell(
                    child: _ParticipantTableContainer(const Text('Total'))
                ),
              ]
          )
      );
    }
    // Footer row
    rowList.add(
        TableRow(
          children: [
            TableCell(
                child: _ParticipantTableContainer(
                  FlatButton(
                    onPressed: () => _showAddParticipantDialog(context),
                    // tooltip: 'Add new Participant',
                    child: const Icon(Icons.add),
                  )
              )
            ),
            TableCell(
              child: Container(
                child: const Text('Remove round?'),
              )
            ),
            TableCell(
              child: Container(
                child: const Text('Add extra round?')
              )
            )
          ]
        )
    );

    return rowList;
  }

}

/// The dialog for adding a new Participant to the Scorable
class _AddParticipantDialog extends StatelessWidget {

  final void Function(String name) callback;

  _AddParticipantDialog(this.callback);

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
    if (_formKey.currentState.validate()) {
      callback(nameController.text);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'The name of the participant to be added',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a name';
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
                )
            )
          ]
      ),
    );
  }

}

class _ParticipantTableContainer extends StatelessWidget {

  final Widget content;

  _ParticipantTableContainer(this.content);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: content,
      padding: EdgeInsets.all(10),
    );
  }
}