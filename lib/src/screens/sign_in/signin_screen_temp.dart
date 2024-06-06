import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const routeName = '/signin';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return SignInScreen(
      headerMaxExtent: 200,
    );
  }
}