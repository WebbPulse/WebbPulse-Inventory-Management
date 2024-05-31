import 'package:flutter/material.dart';


class UsersPage extends StatelessWidget {
  const UsersPage({super.key});


  static const routeName = '/users';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: const Center(
        child: Text('Users Page'),
      ),
    );
  }
}