import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(
        child: RegisterScreen(
          headerMaxExtent: 200,
        ),
      ),
    );
  }
}
