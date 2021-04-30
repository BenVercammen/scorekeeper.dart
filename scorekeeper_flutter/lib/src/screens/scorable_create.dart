
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scorekeeper_flutter/src/screens/scorable_detail.dart';
import 'package:scorekeeper_flutter/src/services/service.dart';

class ScorableCreatePage extends StatefulWidget {

  final ScorekeeperService scorekeeperService;

  ScorableCreatePage(this.scorekeeperService);

  @override
  _ScorableCreatePageState createState() => _ScorableCreatePageState(scorekeeperService);
}


class _ScorableCreatePageState extends State<ScorableCreatePage> {
  final ScorekeeperService _scorekeeperService;

  final _nameController = TextEditingController();

  _ScorableCreatePageState(this._scorekeeperService);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a new game')
      ),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              key: const ValueKey('scorable_name'),
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(hintText: 'The name of your game'),
              autofocus: true,
              controller: _nameController..text = 'New Game',
              onChanged: (value) {
                _nameController.text.trim();
              },
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                onPressed: _cancel,
                child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Cancel'))),
            ElevatedButton(
                onPressed: _createGame,
                child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Create'))),
          ],
        )
      ])

    );
  }

  void _cancel() {
    // TODO: are you sure?? dialog
    Navigator.of(context).pop();
  }

  Future<void> _createGame() async {
    try {
      // TODO: validateInput();
      // TODO: scorekeeperservice create new game
      final scorable = _scorekeeperService.createNewScorable(_nameController.text);
      await Navigator. of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ScorableDetailPage(_scorekeeperService, scorable)));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).errorColor,
          )
      );
    }
  }

}