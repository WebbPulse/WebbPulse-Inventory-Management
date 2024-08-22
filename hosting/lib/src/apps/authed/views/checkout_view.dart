// checkout_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/org_selector_change_notifier.dart';
import '../../../shared/providers/authentication_change_notifier.dart';
import '../../../shared/providers/device_checkout_service.dart';
import '../../../shared/widgets.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Page'),
      ),
      drawer: const AuthedDrawer(),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: CheckoutForm(),
      ),
    );
  }
}

class CheckoutForm extends StatefulWidget {
  const CheckoutForm({super.key});

  @override
  CheckoutFormState createState() => CheckoutFormState();
}

class CheckoutFormState extends State<CheckoutForm> {
  var _isLoading = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    setState(() => _isLoading = true);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    final deviceCheckedOutBy =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
            .user!
            .uid;
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        _controller.text,
        orgId,
        deviceCheckedOutBy,
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Serial Number',
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.login),
          label: const Text('Checkout Serial Number'),
        ),
      ],
    );
  }
}
