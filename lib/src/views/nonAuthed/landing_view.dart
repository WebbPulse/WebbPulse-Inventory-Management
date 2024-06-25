import 'package:flutter/material.dart';
import 'register_view.dart';
import 'signin_view.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  static const routeName = '/landing';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(title: Text('Landing Page')),
      body: Center(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Register'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RegisterView.routeName);
              },
            ),
            ListTile(
              title: Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SignInView.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
