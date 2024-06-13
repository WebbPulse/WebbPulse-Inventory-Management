import 'package:flutter/material.dart';

import '../widgets.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});


  static const routeName = '/users';

  @override
  Widget build(BuildContext context) {
    return const ScaffoldWithDrawer(
      title: 'Users',
      body: Center(
        child: Text('Users Page'),
      ),
    );
  }
}