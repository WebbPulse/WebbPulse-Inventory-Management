import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:webbpulse_inventory_management/src/shared/authentication_provider_list.dart';

/// A ChangeNotifier that manages authentication state
class AuthenticationChangeNotifier extends ChangeNotifier {
  /// Constructor calls the `init` method to set up authentication listeners
  AuthenticationChangeNotifier() {
    init();
  }

  /// A method to manually update the `_userWasLoggedIn` flag
  void setUserWasLoggedIn(bool value) {
    _userWasLoggedIn = value;
    notifyListeners();

    /// Notify listeners of changes in the authentication state
  }

   void setUserEmailVerified(bool value) {
    _userEmailVerified = value;
    notifyListeners();

    /// Notify listeners of changes in the authentication state
  }

  /// Private field to store the currently logged-in user (or null if no user is logged in)
  User? _user;
  /// Public getter to access the current user
  User? get user => _user;

  /// Private field to track if the user has been logged in previously
  bool _userWasLoggedIn = false;
  /// Public getter to check if the user has been logged in before
  bool get userWasLoggedIn => _userWasLoggedIn;

  bool _userEmailVerified = false;
  bool get userEmailVerified => _userEmailVerified;

  /// Private field to track if the user is currently logged in
  bool _userLoggedIn = false;
  /// Public getter to check if the user is currently logged in
  bool get userLoggedIn => _userLoggedIn;

  /// Initializes authentication and listens for changes in the user's authentication state
  Future<void> init() async {
    /// Configure the Firebase UI Auth to use email-based authentication
    FirebaseUIAuth.configureProviders(authenticationProviderList);

    /// Listen for changes in the authentication state (e.g., login, logout)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      /// If the user is logged in
      if (user != null) {
        /// Refresh the user's ID token
        user.getIdToken(true);

        /// Update the private `_user` field with the logged-in user
        _user = user;

        /// Mark the user as currently logged in
        _userLoggedIn = true;

        /// Also mark that the user has been logged in previously
        _userWasLoggedIn = true;

        /// Check if the user's email is verified
        _userEmailVerified = user.emailVerified;
      }

      /// If the user is not logged in
      else {
        /// Clear the `_user` field and mark the user as not logged in
        _user = null;
        _userLoggedIn = false;
      }

      /// Notify listeners (such as UI components) that the authentication state has changed
      notifyListeners();
    });
  }

  /// Signs out the user from Firebase and updates the state accordingly
  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
  }
}
