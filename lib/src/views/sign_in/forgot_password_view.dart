import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, required this.email});

  final String email;
  static const routeName = '/sign-in/forgot-password';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return ForgotPasswordScreen(
      email: email,
      headerMaxExtent: 200,
    );
  }
}
