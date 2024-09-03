import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/providers/authentication_change_notifier.dart';
import '../../../../shared/providers/device_checkout_service.dart';
import '../../../../shared/widgets.dart';

class DeviceCheckoutView extends StatelessWidget {
  const DeviceCheckoutView({super.key});

  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    return OrgDocumentStreamBuilder(
      builder: (context, orgDocument) {
        return Scaffold(
          appBar: const OrgNameAppBar(
            titleSuffix: 'Device Checkout',
          ),
          drawer: const AuthedDrawer(),
          body: Stack(
            children: [
              if (orgDocument['orgBackgroundImageURL'] != null &&
                  orgDocument['orgBackgroundImageURL'] != '')
                Positioned.fill(
                  child: Image.network(
                    orgDocument['orgBackgroundImageURL'],
                    fit: BoxFit.cover,
                  ),
                ),

              // Main content with padding
              const SafeArea(
                child: SizedBox.expand(
                  child: CheckoutForm(),
                ),
              ),
            ],
          ),
        );
      },
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
    ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Set maximum width constraints based on screen size
            double maxWidth;
            if (constraints.maxWidth < 600) {
              maxWidth = constraints.maxWidth * 0.95;
            } else if (constraints.maxWidth < 1200) {
              maxWidth = constraints.maxWidth * 0.6;
            } else {
              maxWidth = constraints.maxWidth * 0.4;
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
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
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.surface.withOpacity(0.95),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.all(16.0)),
                        icon: _isLoading
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.login),
                        label: const Text('Checkout Serial Number'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
