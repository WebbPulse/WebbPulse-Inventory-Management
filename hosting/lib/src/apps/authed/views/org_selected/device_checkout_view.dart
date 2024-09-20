import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';
import 'package:webbcheck/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/device_checkout_service.dart';
import 'package:webbcheck/src/shared/widgets/user_widgets.dart'; // Custom user widgets
import 'package:webbcheck/src/shared/widgets/org_widgets.dart'; // Custom organization widgets
import 'package:webbcheck/src/shared/widgets/device_widgets.dart'; // Custom device-related widgets

/// DeviceCheckoutView is the main view for handling device checkouts and check-ins
class DeviceCheckoutView extends StatelessWidget {
  const DeviceCheckoutView({super.key});

  // Route name for navigation
  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Get the current theme

    // OrgDocumentStreamBuilder provides a stream of the organization's document data
    return OrgDocumentStreamBuilder(
      builder: (context, orgDocument) {
        return Scaffold(
          // AppBar showing the organization's name and "Device Checkout"
          appBar: OrgNameAppBar(
            titleSuffix: 'Device Checkout',
            actions: [
              // Button to open the dialog for adding new devices
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AddDeviceAlertDialog(); // Add device dialog
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
          drawer:
              const AuthedDrawer(), // Navigation drawer for authenticated users

          // Body of the view showing background image and main content
          body: Stack(
            children: [
              // Display background image if it exists in the organization document
              if (orgDocument['orgBackgroundImageURL'] != null &&
                  orgDocument['orgBackgroundImageURL'] != '')
                Positioned.fill(
                  child: Image.network(
                    orgDocument[
                        'orgBackgroundImageURL'], // Load background image
                    fit: BoxFit.cover,
                  ),
                ),

              // Main content (checkout form)
              const SafeArea(
                child: SizedBox.expand(
                  child: CheckoutForm(), // Custom checkout form
                ),
              ),
            ],
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
  var _isLoading = false; // Loading indicator for async operations
  late TextEditingController
      _deviceSerialController; // Controller for the device serial input
  late TextEditingController
      _userSearchController; // Controller for user search input
  String _searchQuery = ''; // Store the current search query

  @override
  void initState() {
    super.initState();
    _deviceSerialController =
        TextEditingController(); // Initialize controller for device serial
    _userSearchController =
        TextEditingController(); // Initialize controller for user search
    _userSearchController.addListener(
        _onSearchChanged); // Listen to changes in the user search input
  }

  @override
  void dispose() {
    _deviceSerialController
        .dispose(); // Dispose controller when widget is destroyed
    _userSearchController.dispose();
    super.dispose();
  }

  // Update the search query when the user types in the search field
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _userSearchController.text;
    });
  }

  // Function to handle device checkout or check-in
  Future<void> _onSubmit(bool checkOut) async {
    setState(() => _isLoading = true); // Show loading indicator
    final orgId = Provider.of<OrgSelectorChangeNotifier>(context, listen: false)
        .orgId; // Get selected organization ID
    final deviceCheckoutService = Provider.of<DeviceCheckoutService>(context,
        listen: false); // Get device checkout service
    final deviceCheckedOutBy =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
            .user!
            .uid; // Get current user's ID
    try {
      // Call the service to handle device checkout or check-in
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        _deviceSerialController.text,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass true for checkout, false for check-in
      );
    } catch (e) {
      // Handle any errors
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  // Function to handle admin-specific checkout or check-in
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
        checkOut,
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show dialog for admins to select a user for device checkout or check-in
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
                    // Search user field
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
                    // Stream of organization members to choose from
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

                          // Filter the list of users based on the search query
                          final filteredDocs = orgMemberDocs.where((doc) {
                            final name = doc['orgMemberDisplayName']
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                          // Show the filtered list of users
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
                                SizedBox(height: 16),
                                Center(child: Text('No users found.')),
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
    ThemeData theme = Theme.of(context); // Get the current theme
    return AuthClaimChecker(builder: (context, userClaims) {
      final orgId =
          Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
      // Check if the user has admin or desk station role
      bool isAdminOrDeskstation = (userClaims['org_admin_$orgId'] == true) ||
          (userClaims['org_deskstation_$orgId'] == true);

      // Main UI for the form, using a layout builder to adjust width constraints
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
                        // Serial Number Input Field
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
                            // Check-out Button
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
