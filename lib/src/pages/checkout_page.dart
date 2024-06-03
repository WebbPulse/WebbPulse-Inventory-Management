import 'package:flutter/material.dart';

import '../drawerandscaffold.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});


  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
     return const DrawerAndScaffold(
      title: 'Checkout',
      body: Center(
        child: Text('Checkout Page'),
      ),
    );
  }
}