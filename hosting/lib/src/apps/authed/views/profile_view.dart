import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseFunctions>(
        builder: (context, firebaseFunctions, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        drawer: const AuthedDrawer(),
        body: ProfileScreen(
          actions: [
            DisplayNameChangedAction(
              (context, user, userDisplayName) async {
                await firebaseFunctions
                    .httpsCallable('update_global_user_display_name_callable')
                    .call(
                  {
                    'userDisplayName': userDisplayName,
                  },
                );
              },
            ),
          ],
          providers: [
            EmailAuthProvider(),
          ],
        ),
      );
    });
  }
}
