import 'package:flutter/material.dart';

class OrgSelectionView extends StatelessWidget {
  const OrgSelectionView({super.key});

  static const routeName = '/select-organization';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(title: Text('Org Selection Page')),
      body: Center(
        child: Text('Org Selection Page'),
      ),
    );
  }
}
