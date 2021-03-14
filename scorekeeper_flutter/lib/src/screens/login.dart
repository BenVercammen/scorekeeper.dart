import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/service.dart';
import 'scorable_overview.dart';

class LoginScreen extends StatefulWidget {
  final ScorekeeperService scorekeeperService;

  const LoginScreen({Key key, this.scorekeeperService}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState(scorekeeperService);
  }
}

class _LoginScreenState extends State<LoginScreen> {
  String _email;

  String _password;

  final auth = FirebaseAuth.instance;

  final ScorekeeperService scorekeeperService;

  _LoginScreenState(this.scorekeeperService);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Login please')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: 'E-mailaddress'),
                onChanged: (value) {
                  _email = value.trim();
                },
              )),
          Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextField(
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: InputDecoration(hintText: 'Password'),
                onChanged: (value) {
                  _password = value.trim();
                },
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () => _signInWithEmailAndPassword(),
                  child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Sign in'))),
              ElevatedButton(
                  onPressed: () => _createUserWithEmailAndPassword(),
                  child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Sign up'))),
            ],
          )
        ]));
  }

  Future<UserCredential> _createUserWithEmailAndPassword() async {
    final userCredential = await auth.createUserWithEmailAndPassword(email: _email, password: _password);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ScorableOverviewPage(title: 'Scorekeeper', scorekeeperService: scorekeeperService)));
    return userCredential;
  }

  Future<UserCredential> _signInWithEmailAndPassword() async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(email: _email, password: _password);
      log(userCredential.toString());
      // log(userCredential.user.displayName);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ScorableOverviewPage(title: 'Scorekeeper', scorekeeperService: scorekeeperService)));
    } on Exception catch (e) {
      // TODO: show error message!
      log(e.toString());
    }

  }
}
