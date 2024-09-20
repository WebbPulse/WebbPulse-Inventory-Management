import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';

import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/providers/authentication_change_notifier.dart';
import '../../../../shared/providers/device_checkout_service.dart';
import 'package:webbcheck/src/shared/widgets/user_widgets.dart';
import 'package:webbcheck/src/shared/widgets/org_widgets.dart';
import '../../../../shared/widgets/device_widgets.dart';

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
  late TextEditingController _userSearchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _deviceSerialController = TextEditingController();
    _userSearchController = TextEditingController();
    _userSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _deviceSerialController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _userSearchController.text;
    });
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

  Future<void> _onSubmitAdminAndDeskstation(
      bool checkOut, String deviceCheckedOutBy) async {
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(checkOut
                  ? 'Confirm Check-out User'
                  : 'Confirm Check-in User'),
              content:
                  Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
                      builder: (context, firestoreReadService,
                          orgSelectorChangeNotifier, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkOut
                          ? 'Select the user to check-out this device.'
                          : 'Select the user to check-in this device.',
                    ),
                    TextField(
                      controller: _userSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Search User',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    StreamBuilder<List<DocumentSnapshot>>(
                        stream: firestoreReadService.getOrgMembersDocuments(
                            orgSelectorChangeNotifier.orgId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading users'));
                          }
                          final List<DocumentSnapshot> orgMemberDocs =
                              snapshot.data!;

                          // Filter the list based on the search query
                          final filteredDocs = orgMemberDocs.where((doc) {
                            final name = doc['orgMemberDisplayName']
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                          if (filteredDocs.isNotEmpty) {
                            return Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: filteredDocs.map((orgMemberDoc) {
                                    return ListTile(
                                      title: Text(
                                          orgMemberDoc['orgMemberDisplayName']),
                                      subtitle:
                                          Text(orgMemberDoc['orgMemberEmail']),
                                      onTap: () {
                                        _onSubmitAdminAndDeskstation(
                                          checkOut,
                                          orgMemberDoc.id,
                                        );
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          } else {
                            return const Column(
                              children: [
                                SizedBox(
                                  height: 16,
                                ),
                                Center(
                                  child: Text('No users found.'),
                                ),
                              ],
                            );
                          }
                        }),
                  ],
                );
              }),
              actions: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
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
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AuthClaimChecker(builder: (context, userClaims) {
      final orgId =
          Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
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
                                backgroundColor:
                                    theme.colorScheme.surface.withOpacity(0.95),
                                side: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.all(16.0),
                              ),
                              icon: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.logout),
                              label: const Text('Check-out Device'),
                            ),
                            // Check-in Button
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _onSubmit(false);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surface.withOpacity(0.95),
                                side: BorderSide(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.5),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.all(16.0),
                              ),
                              icon: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.login),
                              label: const Text('Check-in Device'),
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
    });
  }
}
