import 'package:flutter/material.dart';

import '../drawerandscaffold.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});


  static const routeName = '/users';

  @override
  Widget build(BuildContext context) {
    return DrawerAndScaffold(
      title: 'Users',
      body: const Center(
        child: Text('Users Page'),
      ),
    );
  }
}