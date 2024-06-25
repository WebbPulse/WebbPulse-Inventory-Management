import 'package:flutter/material.dart';

import '../../widgets.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});

  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return const ScaffoldWithDrawer(
      title: 'Devices',
      body: Center(
        child: Text('Devices Page'),
      ),
    );
  }
}
