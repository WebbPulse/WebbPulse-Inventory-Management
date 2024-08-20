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

  bool _userWasLoggedIn = false; // Track if the user was logged in previously
  bool get userWasLoggedIn => _userWasLoggedIn;

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
      /// user IS NOT logged and
      /// WAS logged in previously
      if (user == null && _userWasLoggedIn) {
        _userLoggedIn = false;
        _uid = null;
        _userEmail = null;
        _userVerified = false;
        _userDisplayName = null;
      }

      /// user IS logged in
      else if (user != null) {
        _userLoggedIn = true;
        _uid = user.uid;
        _userEmail = user.email;
        _userVerified = user.emailVerified;
        _userDisplayName = user.displayName;
        _userWasLoggedIn = true;

        /// mark the user as having been logged in previously
      }

      /// user IS NOT logged in and
      /// WAS NOT logged in previously
      else {
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
