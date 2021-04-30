import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/service.dart';
import 'scorable_overview.dart';

class LoginScreen extends StatefulWidget {
  final ScorekeeperService scorekeeperService;

  const LoginScreen({Key? key, required this.scorekeeperService}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState(scorekeeperService);
  }
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final auth = FirebaseAuth.instance;

  final ScorekeeperService scorekeeperService;

  _LoginScreenState(this.scorekeeperService);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Login please')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextFormField(
                key: const ValueKey('email'),
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'E-mailaddress'),
                autofocus: true,
                controller: _emailController..text = 'test@example.com',
                onChanged: (value) {
                  _emailController.text.trim();
                },
              )),
          Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextFormField(
                key: const ValueKey('password'),
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
                controller: _passwordController..text = 'test123',
                onChanged: (value) {
                  _passwordController.text.trim();
                },
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: _signInWithEmailAndPassword,
                  child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Sign in'))),
              ElevatedButton(
                  onPressed: _createUserWithEmailAndPassword,
                  child: const Padding(padding: EdgeInsets.all(5.0), child: Text('Sign up'))),
            ],
          )
        ]));
  }

  Future<void> _createUserWithEmailAndPassword() async {
    try {
      validateInput();
      await auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ScorableOverviewPage(scorekeeperService: scorekeeperService)));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).errorColor,
          )
      );
    }
  }

  void validateInput() {
    if (_emailController.text.isEmpty) {
      throw Exception('Email address is required.');
    }
    if (!_emailController.text.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (_passwordController.text.isEmpty) {
      throw Exception('Password is required.');
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    try {
      validateInput();
      final userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      log(userCredential.toString());
      // log(userCredential.user.displayName);
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              ScorableOverviewPage(scorekeeperService: scorekeeperService)));
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
