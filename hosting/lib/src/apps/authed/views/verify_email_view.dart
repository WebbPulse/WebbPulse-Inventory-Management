import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

/// VerifyEmailView provides the screen for email verification using Firebase UI.
class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/verify-email';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Verify Email'), // Title of the AppBar for the verification screen
      ),
      body:
          const EmailVerificationScreen(), // Firebase UI screen for email verification
    );
  }
}
