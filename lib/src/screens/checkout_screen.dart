import 'package:flutter/material.dart';

import '../makemylifefaster/scaffoldwithdrawer.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});


  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
     return const ScaffoldWithDrawer(
      title: 'Checkout',
      body: Center(
        child: Text('Checkout Page'),
      ),
    );
  }
}