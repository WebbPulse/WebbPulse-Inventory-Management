import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';

import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/providers/authentication_change_notifier.dart';
import '../../../../shared/providers/device_checkout_service.dart';
import '../../../../shared/widgets.dart';

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
            titleSuffix: 'Device Checkout',
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
                        backgroundColor:
                            theme.colorScheme.surface.withOpacity(0.95),
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

  Future<void> _onSubmit(bool checkOut) async {
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
        _deviceSerialController.text,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass the boolean for checkout or check-in
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSubmitAdminAndDeskstation(bool checkOut, String deviceCheckedOutBy) async {
    setState(() => _isLoading = true);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        _deviceSerialController.text,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass the boolean for checkout or check-in
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAdminDialog(bool checkOut, String orgId) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      ThemeData theme = Theme.of(context);
      return AlertDialog(
        title: Text(checkOut ? 'Confirm Check-out User' : 'Confirm Check-in User'),
        content: Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
          builder: (context, firestoreReadService, orgSelectorChangeNotifier, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                        checkOut
                            ? 'Select the user to check-out this device.'
                            : 'Select the user to check-in this device.',
                      ),
                StreamBuilder<List<DocumentSnapshot>>(
                  stream: firestoreReadService.getOrgMembersDocuments(
                        orgSelectorChangeNotifier.orgId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading users'));
                    }
                    final List<DocumentSnapshot> orgMemberDocs =
                          snapshot.data!;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var orgMemberDoc in orgMemberDocs)
                            ListTile(
                              title: Text(orgMemberDoc['orgMemberDisplayName']),
                              subtitle: Text(orgMemberDoc['orgMemberEmail']),
                              onTap: () {
                                Navigator.of(context).pop(orgMemberDoc.id);
                              },
                            ),
                        ],
                      ),
                    );
                  }
          ),
              ],
            );
          }
        ),
        actions: <Widget>[
          // Checkout Button
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    
                    /////DO THIS LATER!!!!!!!!!!!!!!!!!!!1
                    
                    final deviceCheckedOutBy =
                        ///replave this checked out by logic
                        
                        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
                            .user!
                            .uid;
                    _onSubmitAdminAndDeskstation(checkOut, deviceCheckedOutBy);
                    Navigator.of(context).pop(); // Close dialog after action
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.all(16.0),
            ),
            icon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.logout),
            label: Text(checkOut ? 'Confirm Check-out Serial Number' : 'Confirm Check-in Serial Number',),
          ),
          const SizedBox(width: 8.0, height: 8.0),
          ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.all(16.0),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AuthClaimChecker(
      builder: (context, userClaims) {
        final orgId = Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
        // Safely check if the roles exist and their values are true
        bool isAdminOrDeskstation = (userClaims['org_admin_$orgId'] == true) ||
                                  (userClaims['org_deskstation_$orgId'] == true);

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
                            controller: _deviceSerialController,
                            decoration: const InputDecoration(
                              labelText: 'Serial Number',
                            ),
                          ),
                          const SizedBox(height: 16.0),
        
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              // Checkout Button
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (isAdminOrDeskstation) {
                                          _showAdminDialog(true, orgId);
                                        } else {
                                          _onSubmit(true);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                ),
                                icon: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Icon(Icons.logout),
                                label: const Text('Check-out Serial Number'),
                              ),
                              // Check-in Button
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (isAdminOrDeskstation) {
                                          _showAdminDialog(false, orgId);
                                        } else {
                                          _onSubmit(false);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
                                  side: BorderSide(
                                    color: theme.colorScheme.secondary.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                ),
                                icon: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Icon(Icons.login),
                                label: const Text('Check-in Serial Number'),
                              ),
                            ],
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
    );
  }
}

