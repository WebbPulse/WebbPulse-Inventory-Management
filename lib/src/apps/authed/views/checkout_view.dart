// checkout_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/orgSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/providers/firestoreService.dart';
import 'package:webbcheck/src/shared/providers/deviceCheckoutService.dart';

import '../../../shared/widgets.dart';

class CheckoutView extends StatelessWidget {
  CheckoutView({super.key});

  final TextEditingController _controller = TextEditingController();

  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgSelectorChangeNotifier, FirestoreService,
        DeviceCheckoutService>(
      builder: (context, orgSelectorProvider, firestoreService,
          deviceCheckoutService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout Page'),
          ),
          drawer: const AuthedDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    final deviceSerialNumber = _controller.text;
                    await deviceCheckoutService.handleDeviceCheckout(
                      context,
                      deviceSerialNumber,
                      orgSelectorProvider.selectedOrgId,
                    );
                  },
                  child: const Text('Checkout Serial Number'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
