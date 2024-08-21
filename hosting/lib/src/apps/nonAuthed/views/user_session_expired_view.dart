import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/apps/nonAuthed/views/landing_view.dart';

import '../../../shared/providers/authenticationChangeNotifier.dart';

class UserSessionExpiredView extends StatelessWidget {
  const UserSessionExpiredView({super.key});

  static const routeName = '/user_session_expired';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Session Expired')),
      body: Center(
        child: Consumer<AuthenticationChangeNotifier>(
          builder: (context, authenticationChangeNotifier, child) => Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('User Session Expired'),
              ElevatedButton(
                onPressed: () {
                  authenticationChangeNotifier.setUserWasLoggedIn(false);
                  Navigator.pop(context);
                  Navigator.pushNamed(context, LandingView.routeName);
                },
                child: const Text('Please Sign In Again'),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
