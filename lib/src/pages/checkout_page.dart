import 'package:flutter/material.dart';


class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});


  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: const Center(
        child: Text('Checkout Page'),
      ),
    );
  }
}