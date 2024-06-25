import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../../widgets.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithDrawer(
      title: 'Profile',
      body: ProfileScreen(
        providers: [
          EmailAuthProvider(),
        ],
      ),
    );
  }
}
