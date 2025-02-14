import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart'; // Custom user widgets
import 'package:webbpulse_inventory_management/src/shared/widgets/org_widgets.dart'; // Custom organization widgets
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/add_device_alert_dialog.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/device_checkout_button.dart';
import 'dart:io';

/// DeviceCheckoutView is the main view for handling device checkouts and check-ins
class DeviceCheckoutView extends StatelessWidget {
  const DeviceCheckoutView({super.key});

  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return OrgDocumentStreamBuilder(
      builder: (context, orgDocument) {
        return Scaffold(
          appBar: OrgNameAppBar(
            titleSuffix: 'Checkout',
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AddDeviceAlertDialog();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                label: const Text('Add New Device'),
                icon: const Icon(Icons.add),
              )
            ],
          ),
          drawer: const AuthedDrawer(),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate isIPad based on the width constraints
              final bool isIPad =
                  !kIsWeb && Platform.isIOS && constraints.maxWidth >= 600;

              return Stack(
                children: [
                  if (orgDocument['orgBackgroundImageURL'] != null &&
                      orgDocument['orgBackgroundImageURL'] != '')
                    Positioned.fill(
                      child: Image.network(
                        orgDocument['orgBackgroundImageURL'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  SafeArea(
                    child: SizedBox.expand(
                      child: isIPad
                          ? const Center(child: CheckoutForm())
                          : const CheckoutForm(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// CheckoutForm handles the form input and logic for device checkout and check-in
class CheckoutForm extends StatefulWidget {
  const CheckoutForm({super.key});

  @override
  CheckoutFormState createState() => CheckoutFormState();
}

class CheckoutFormState extends State<CheckoutForm> {
  late TextEditingController _deviceSerialController;

  @override
  void initState() {
    super.initState();
    _deviceSerialController = TextEditingController();
  }

  @override
  void dispose() {
    _deviceSerialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthClaimChecker(builder: (context, userClaims) {
      return SingleChildScrollView(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double maxWidth;
              if (constraints.maxWidth < 600) {
                maxWidth = constraints.maxWidth * 0.95;
              } else if (constraints.maxWidth < 1200) {
                maxWidth = constraints.maxWidth * 0.6;
              } else {
                maxWidth = constraints.maxWidth * 0.4;
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
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
                          controller: _deviceSerialController,
                          decoration: const InputDecoration(
                            labelText: 'Serial Number',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _deviceSerialController,
                          builder: (context, value, child) {
                            return DeviceCheckoutButton(
                              key: ValueKey(value.text),
                              deviceSerialNumber: value.text,
                            );
                          },
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
    });
  }
}
