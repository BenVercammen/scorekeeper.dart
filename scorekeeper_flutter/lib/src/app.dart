import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'screens/login.dart';
import 'services/service.dart';

class ScorableApp extends StatelessWidget {

  final Logger _logger = Logger();

  // The ScorekeeperService
  final ScorekeeperService _scorekeeperService;

  // Create the initialization Future outside of `build`:
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  ScorableApp(this._scorekeeperService) {
    _logger.d(_initialization);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scorekeeper Demo Application - Muurke Klop',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      // home: ScorableOverviewPage(title: 'Scorekeeper Demo Application - Muurke Klop', scorekeeperService: _scorekeeperService),
      home: LoginScreen(scorekeeperService: _scorekeeperService),
    );
  }
}
