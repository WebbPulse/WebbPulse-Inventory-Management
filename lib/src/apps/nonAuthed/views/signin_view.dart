import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/authenticationProvider.dart';
import '../../authed/views/home_view.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  static const routeName = '/signin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Consumer<AuthenticationProvider>(
          builder: (context, authProvider, child) => SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushNamed(context, HomeView.routeName);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
