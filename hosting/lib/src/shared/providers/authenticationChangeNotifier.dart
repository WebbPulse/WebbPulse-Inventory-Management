import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenticationChangeNotifier extends ChangeNotifier {
  AuthenticationChangeNotifier() {
    init();
  }

  bool _userLoggedIn = false;
  bool get userLoggedIn => _userLoggedIn;

  String? _uid;
  String? get uid => _uid;

  String? _userEmail;
  String? get userEmail => _userEmail;

  bool _userVerified = false;
  bool get userVerified => _userVerified;

  String? _userDisplayName;
  String? get userDisplayName => _userDisplayName;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userLoggedIn = true;
        _uid = user.uid;
        _userEmail = user.email;
        _userVerified = user.emailVerified;
        _userDisplayName = user.displayName;
      } else {
        _userLoggedIn = false;
        _uid = null;
        _userEmail = null;
        _userVerified = false;
        _userDisplayName = null;
      }
      notifyListeners();
    });
  }
}
