import 'package:flutter/material.dart';

import '../drawerandscaffold.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});


  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
     return DrawerAndScaffold(
      title: 'Devices',
      body: const Center(
        child: Text('Devices Page'),
      ),
    );
  }
}