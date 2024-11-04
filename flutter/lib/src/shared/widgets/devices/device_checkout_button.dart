import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/device_checkout_service.dart';
import '../../providers/org_selector_change_notifier.dart';
import '../../providers/firestore_read_service.dart';
import '../../providers/authentication_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';

class DeviceCheckoutButton extends StatefulWidget {
  final String deviceSerialNumber; // The serial number of the device

  const DeviceCheckoutButton({
    super.key,
    required this.deviceSerialNumber,
  });

  @override
  DeviceCheckoutButtonState createState() => DeviceCheckoutButtonState();
}

class DeviceCheckoutButtonState extends State<DeviceCheckoutButton> {
  var _isLoading = false; // Flag to indicate if an operation is in progress
  late TextEditingController
      _userSearchController; // Controller for the user search field
  String _searchQuery = ''; // Search query for filtering users
  late TextEditingController
      _deviceCheckedOutNoteController; // Controller for the note field
  String _deviceCheckedOutNote = ''; // Note for the check-out operation

  @override
  void initState() {
    super.initState();
    _userSearchController =
        TextEditingController(); // Initialize the search controller
    _userSearchController.addListener(
        _onSearchChanged); // Listen for changes in the search field
    _deviceCheckedOutNoteController =
        TextEditingController(); // Initialize the note controller
  }

  @override
  void dispose() {
    _userSearchController.dispose(); // Dispose the search controller
    _deviceCheckedOutNoteController.dispose(); // Dispose the note controller
    super.dispose();
  }

  /// Updates the search query when the text field changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _userSearchController.text;
    });
  }

  /// Handles the submission of the check-in or check-out operation
  Future<void> _changeDeviceStatus(
      bool isDeviceCheckedOut, String deviceCheckedOutNote) async {
    setState(() => _isLoading = true); // Set loading state
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckedOutBy =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
            .user!
            .uid;
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
        isDeviceCheckedOut, // Pass the boolean to check-out or check-in the device
        deviceCheckedOutNote, // Pass the note for the check-out operation
      );
    } catch (e) {
      // Handle errors if needed
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Handles the submission of check-in/check-out by admins or desk stations
  Future<void> _changeDeviceStatusAdminAndDeskstation(bool isDeviceCheckedOut,
      String deviceCheckedOutBy, String deviceCheckedOutNote) async {
    setState(() => _isLoading = true); // Set loading state
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
        isDeviceCheckedOut, // Pass the boolean for check-in or check-out
        deviceCheckedOutNote, // Pass the note for the check-out operation
      );
    } catch (e) {
      // Handle errors if needed
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Shows a dialog for admin or desk station users to select a user for check-in/check-out
  Future<void> _showUserListDialog(bool isDeviceCheckedOut, String orgId,
      String deviceCheckedOutNote) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        ThemeData theme = Theme.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(isDeviceCheckedOut
                  ? 'Confirm Check-out User'
                  : 'Confirm Check-in User'), // Title based on check-out or check-in
              content:
                  Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
                      builder: (context, firestoreReadService,
                          orgSelectorChangeNotifier, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeviceCheckedOut
                          ? 'Select the user to check-out this device.'
                          : 'Select the user to check-in this device.', // Instruction text
                    ),
                    TextField(
                      controller:
                          _userSearchController, // Search field for users
                      decoration: const InputDecoration(
                        labelText: 'Search User',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value; // Update search query
                        });
                      },
                    ),
                    StreamBuilder<List<DocumentSnapshot>>(
                        stream: firestoreReadService.getOrgMembersDocuments(
                            orgSelectorChangeNotifier
                                .orgId), // Stream to fetch organization members
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child:
                                    CircularProgressIndicator()); // Show loading indicator
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text(
                                    'Error loading users')); // Show error message
                          }
                          final List<DocumentSnapshot> orgMemberDocs =
                              snapshot.data!;

                          // Filter members based on search query
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
                                      title: Text(orgMemberDoc[
                                          'orgMemberDisplayName']), // Display member name
                                      subtitle: Text(orgMemberDoc[
                                          'orgMemberEmail']), // Display member email
                                      onTap: () {
                                        _changeDeviceStatusAdminAndDeskstation(
                                            isDeviceCheckedOut,
                                            orgMemberDoc.id,
                                            _deviceCheckedOutNote // Submit with selected member
                                            );
                                        Navigator.of(context)
                                            .pop(); // Close dialog
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
                                  child: Text(
                                      'No users found.'), // Message when no users match search
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
                    Navigator.of(context).pop(); // Close note dialog
                    _showCheckoutNoteDialog(isDeviceCheckedOut,
                        orgId); // Show note dialog for check-out
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
                  label: const Text('Go Back'), // Button to go back
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog for admin or desk station users to select a user for check-in/check-out
  Future<void> _showCheckoutNoteDialog(
      bool isDeviceCheckedOut, String orgId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AuthClaimChecker(
          builder: (context, userClaims) {
            ThemeData theme = Theme.of(context);
            final orgId =
                Provider.of<OrgSelectorChangeNotifier>(context, listen: false)
                    .orgId;
            // Check if the user is an admin or desk station for this organization
            bool isAdminOrDeskstation =
                (userClaims['org_admin_$orgId'] == true) ||
                    (userClaims['org_deskstation_$orgId'] == true);
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: const Text('Please Leave a Note'), // Title
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please describe why you are checking out this device', // Instruction text
                      ),
                      TextField(
                        controller:
                            _deviceCheckedOutNoteController, // Search field for users
                        decoration: const InputDecoration(
                          labelText: 'Leave a Note',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _deviceCheckedOutNote =
                              _deviceCheckedOutNoteController.text;
                        });

                        if (isAdminOrDeskstation && !isDeviceCheckedOut) {
                          Navigator.of(context).pop(); // Close note dialog
                          _showUserListDialog(true, orgId,
                              _deviceCheckedOutNote); // Show user list dialog if admin or desk station
                        } else {
                          Navigator.of(context).pop(); // Close note dialog
                          _changeDeviceStatus(!isDeviceCheckedOut,
                              _deviceCheckedOutNote); // Submit the action (check-in or check-out)
                        }
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
                      icon: const Icon(Icons.logout),
                      label:
                          const Text('Check Out Device'), // Button to go back
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
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
                      label: const Text('Go Back'), // Button to go back
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Fetch the current theme
    return Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(builder:
        (context, orgSelectorChangeNotifier, firestoreReadService, child) {
      return StreamBuilder<bool>(
          stream: firestoreReadService.isDeviceCheckedOutInFirestoreStream(
              widget.deviceSerialNumber, orgSelectorChangeNotifier.orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final bool isDeviceCheckedOut = snapshot.data ?? false;

            return AuthClaimChecker(builder: (context, userClaims) {
              final orgId =
                  Provider.of<OrgSelectorChangeNotifier>(context, listen: false)
                      .orgId;

              return ElevatedButton.icon(
                  onPressed: widget.deviceSerialNumber == ''
                      ? null
                      : _isLoading
                          ? null
                          : () {
                              if (isDeviceCheckedOut == false) {
                                _showCheckoutNoteDialog(isDeviceCheckedOut,
                                    orgId); // Show note dialog
                              } else {
                                _changeDeviceStatus(!isDeviceCheckedOut,
                                    ''); // Submit the action
                              }
                            }, // Disable button when loading
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : Icon(isDeviceCheckedOut
                          ? Icons.logout
                          : Icons.login), // Icon for check-in/check-out
                  label: Text(widget.deviceSerialNumber == ''
                      ? 'Please enter a serial number'
                      : isDeviceCheckedOut
                          ? 'Check-in Device'
                          : 'Check-out Device'), // Label for the button
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.surface.withOpacity(0.95),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.all(16.0),
                  ));
            });
          });
    });
  }
}
