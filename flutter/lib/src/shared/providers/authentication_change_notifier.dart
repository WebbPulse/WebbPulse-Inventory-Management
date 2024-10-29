import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:webbpulse_inventory_management/src/shared/authentication_provider_list.dart';

class AuthenticationChangeNotifier extends ChangeNotifier {
  AuthenticationChangeNotifier() {
    init();
  }

  User? _user;
  bool _userWasLoggedIn = false;
  bool _userEmailVerified = false;
  bool _userLoggedIn = false;

  User? get user => _user;
  bool get userWasLoggedIn => _userWasLoggedIn;
  bool get userEmailVerified => _userEmailVerified;
  bool get userLoggedIn => _userLoggedIn;

  Future<void> init() async {
    FirebaseUIAuth.configureProviders(authenticationProviderList);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        user.getIdToken(true);
        _user = user;
        _userLoggedIn = true;
        _userWasLoggedIn = true;
        _userEmailVerified = user.emailVerified;
      } else {
        _user = null;
        _userLoggedIn = false;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithCustomToken(String token) async {
    try {
      await FirebaseAuth.instance.signInWithCustomToken(token);
      _user = FirebaseAuth.instance.currentUser;
      _userLoggedIn = true;
      _userWasLoggedIn = true;
      _userEmailVerified = _user?.emailVerified ?? false;
      notifyListeners();
    } catch (e) {
      // Handle sign-in error (e.g., show error message in UI)
      print("Failed to sign in with custom token: $e");
      rethrow;
    }
  }

  void setUserWasLoggedIn(bool value) {
    _userWasLoggedIn = value;
    notifyListeners();
  }

  void setUserEmailVerified(bool value) {
    _userEmailVerified = value;
    notifyListeners();
  }

  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _userLoggedIn = false;
    notifyListeners();
  }
}
