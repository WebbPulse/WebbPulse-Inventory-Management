import 'package:flutter/material.dart';

import '../drawerandscaffold.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});


  static const routeName = '/users';

  @override
  Widget build(BuildContext context) {
    return const DrawerAndScaffold(
      title: 'Users',
      body: Center(
        child: Text('Users Page'),
      ),
    );
  }
}