import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

class AuthenticationState extends ChangeNotifier {
  AuthenticationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;
  String? _uid;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _uid = user.uid;
      } else {
        _loggedIn = false;
        _uid = null;
      }
      notifyListeners();
    });
  }

  
}
