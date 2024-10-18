import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

/// RegisterView provides the screen for user registration using Firebase UI.
class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'), // Display "Register" title in the AppBar
      ),
      body: const Center(
        // Firebase UI's RegisterScreen handles user registration process
        child: RegisterScreen(
          headerMaxExtent:
              200, // Set the maximum header extent for the registration screen
        ),
      ),
    );
  }
}
