// checkout_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/providers/orgSelectorProvider.dart';
import 'package:webbcheck/src/services/firestoreService.dart';

import '../../widgets.dart';
import '../../services/deviceCheckoutService.dart';

class CheckoutView extends StatelessWidget {
  CheckoutView(
      {super.key,
      required this.firestoreService,
      required this.deviceCheckoutService});

  static const routeName = '/checkout';
  final TextEditingController _controller = TextEditingController();
  final FirestoreService firestoreService;
  final DeviceCheckoutService deviceCheckoutService;

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) {
        return ScaffoldWithDrawer(
          title: 'Checkout Page',
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
                      orgSelectorProvider.selectedOrgUid,
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
