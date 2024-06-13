import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthenticationProvider extends ChangeNotifier {
  AuthenticationProvider() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;
  
  String? _authUid;
  String? get authUid => _authUid;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _authUid = user.uid;
      } else {
        _loggedIn = false;
        _authUid = null;
      }
      notifyListeners();
    });
  }
}