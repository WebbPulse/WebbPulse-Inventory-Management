import 'package:flutter/material.dart';
import '../../../shared/widgets.dart';

class SignUpCompleteView extends StatelessWidget {
  const SignUpCompleteView({super.key});
  static const routeName = '/signupcomplete';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up Complete'),
      ),
      drawer: const AuthedDrawer(),
      body: Center(
        child: Column(
          children: [
            Text('Sign Up Complete!'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/users');
              },
              child: Text('Continue to Users Page'),
            ),
          ],
        ),
      ),
    );
  }
}
