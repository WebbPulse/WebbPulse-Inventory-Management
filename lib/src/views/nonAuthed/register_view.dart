import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return RegisterScreen(
      headerMaxExtent: 200,
    );
  }
}