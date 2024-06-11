import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:webbpulse_checkout/src/screens/home_screen.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const routeName = '/signin';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return SignInScreen(
      providers: [
              EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          // Navigate to home page after sign-in
          Navigator.pushNamed(context, HomeScreen.routeName);
        }),
      ],
    );
  }
}