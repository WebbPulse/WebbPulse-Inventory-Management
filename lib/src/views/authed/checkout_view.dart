import 'package:flutter/material.dart';

import '../../widgets.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

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
