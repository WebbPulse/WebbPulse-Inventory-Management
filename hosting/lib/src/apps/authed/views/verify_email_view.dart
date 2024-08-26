import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});
  static const routeName = '/verify-email';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: const EmailVerificationScreen(),
    );
  }
}
