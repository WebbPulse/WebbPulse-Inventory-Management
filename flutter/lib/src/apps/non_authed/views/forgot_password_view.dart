import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

/// ForgotPasswordView provides the screen for users to reset their password.
class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/forgot-password';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'), // Title of the app bar
      ),
      body: const Center(
        // Firebase UI's ForgotPasswordScreen handles the password reset process
        child: ForgotPasswordScreen(
          headerMaxExtent:
              200, // Set the maximum header extent for the forgot password screen
        ),
      ),
    );
  }
}
