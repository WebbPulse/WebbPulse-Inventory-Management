import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenticationChangeNotifier extends ChangeNotifier {
  AuthenticationChangeNotifier() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String? _uid;
  String? get uid => _uid;

  String? _email;
  String? get email => _email;

  bool _verified = false;
  bool get verified => _verified;

  String? _displayName;
  String? get displayName => _displayName;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _uid = user.uid;
        _email = user.email;
        _verified = user.emailVerified;
        _displayName = user.displayName;
      } else {
        _loggedIn = false;
        _uid = null;
        _email = null;
        _verified = false;
        _displayName = null;
      }
      print('Auth state changed: loggedIn=$_loggedIn, uid=$_uid');
      notifyListeners();
    });
  }
}
