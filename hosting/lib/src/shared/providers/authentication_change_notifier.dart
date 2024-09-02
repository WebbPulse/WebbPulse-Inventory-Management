import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenticationChangeNotifier extends ChangeNotifier {
  AuthenticationChangeNotifier() {
    init();
  }
  void setUserWasLoggedIn(bool value) {
    _userWasLoggedIn = value;
    notifyListeners();
  }

  User? _user;
  User? get user => _user;

  bool _userWasLoggedIn = false; // Track if the user was logged in previously
  bool get userWasLoggedIn => _userWasLoggedIn;

  bool _userLoggedIn = false;
  bool get userLoggedIn => _userLoggedIn;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      /// user IS logged in
      if (user != null) {
        _user = user;
        _userLoggedIn = true;
        _userWasLoggedIn = true;

        /// mark the user as having been logged in previously
      }

      /// user IS NOT logged in and
      /// WAS NOT logged in previously
      else {
        _user = null;
        _userLoggedIn = false;
      }
      notifyListeners();
    });
  }
}
