import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'dart:async';

class AuthenticationProvider extends ChangeNotifier {
  AuthenticationProvider() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String? _uid;
  String? get uid => _uid;

  String? _email;
  String? get email => _email;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _uid = user.uid;
        _email = user.email;
      } else {
        _loggedIn = false;
        _uid = null;
        _email = null;
      }
      print('Auth state changed: loggedIn=$_loggedIn, uid=$_uid');
      notifyListeners();
    });
  }
}
