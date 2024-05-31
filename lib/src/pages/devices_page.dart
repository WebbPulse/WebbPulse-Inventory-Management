import 'package:flutter/material.dart';


class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});


  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: const Center(
        child: Text('Devices Page'),
      ),
    );
  }
}