import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      providers: const [],
      actions: [
        SignedOutAction((context) {
          Navigator.pushReplacementNamed(context, '/');
        }),
      ],
    );
  }
}
