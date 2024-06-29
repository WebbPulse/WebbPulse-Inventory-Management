import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/authenticationProvider.dart';
import '../../services/firestoreService.dart';
import '../authed/home_view.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key, required this.firestoreService});

  static const routeName = '/signin';

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) => SignInScreen(
        providers: [
          EmailAuthProvider(),
        ],
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) {
            Navigator.pop(context);
            Navigator.pushNamed(context, HomeView.routeName);
          }),
        ],
      ),
    );
  }
}
