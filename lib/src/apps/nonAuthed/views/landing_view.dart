import 'package:flutter/material.dart';
import 'register_view.dart';
import 'signin_view.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(title: const Text('Landing Page')),
      body: Center(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('Register'),
              onTap: () {
                Navigator.pushNamed(context, RegisterView.routeName);
              },
            ),
            ListTile(
              title: const Text('Sign In'),
              onTap: () {
                Navigator.pushNamed(context, SignInView.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
