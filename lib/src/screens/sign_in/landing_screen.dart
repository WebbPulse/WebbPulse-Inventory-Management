import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});


  static const routeName = '/landing';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
     return Scaffold(
      appBar: AppBar(title: Text('Landing Page')),
      body: Center(
        child:ListView(
          children: <Widget>[
            ListTile(
              title: Text('Register'),
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            ListTile(
              title: Text('Sign In'),
              onTap: () {
                Navigator.pushNamed(context, '/signin');
              },
            ),
          ],
        ),
      ),
    );
  }
}