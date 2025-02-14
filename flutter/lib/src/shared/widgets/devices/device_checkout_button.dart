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

  @override
  void initState() {
    super.initState();
    
  }

  @override
  void dispose() {
    super.dispose();
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
            final bool isDeviceCurrentlyCheckedOut = snapshot.data ?? false;

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
                              if (isDeviceCurrentlyCheckedOut == true) {
                                _changeDeviceStatus(false,
                                    ''); // Submit the action
                              } else {
                                _showCheckoutNoteDialog(true,
                                    orgId); // Show note dialog
                              }
                            }, // Disable button when loading
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : Icon(isDeviceCurrentlyCheckedOut
                          ? Icons.login
                          : Icons.logout), // Icon for check-in/check-out
                  label: Text(widget.deviceSerialNumber == ''
                      ? 'Please enter a serial number'
                      : isDeviceCurrentlyCheckedOut
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

  Future<void> _showCheckoutNoteDialog(bool isDeviceBeingCheckedOut, String orgId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AuthClaimChecker(
          builder: (context, userClaims) {
            bool isAdminOrDeskstation = (userClaims['org_admin_$orgId'] == true) ||
                (userClaims['org_deskstation_$orgId'] == true);
            return CheckoutNoteDialog(
              isDeviceBeingCheckedOut: isDeviceBeingCheckedOut,
              orgId: orgId,
              isAdminOrDeskstation: isAdminOrDeskstation,
              onSubmit: (deviceCheckedOutNote) {
                if (isAdminOrDeskstation && isDeviceBeingCheckedOut) {
                  // For admin/deskstation users, show the user list dialog
                  _showUserListDialog(isDeviceBeingCheckedOut, orgId, deviceCheckedOutNote);
                } else {
                  // Otherwise, directly change the device status
                  _changeDeviceStatus(isDeviceBeingCheckedOut, deviceCheckedOutNote);
                }
              },
            );
          },
        );
      },
    );
  }

Future<void> _showUserListDialog(bool isDeviceCheckedOut, String orgId, String deviceCheckedOutNote) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return UserListDialog(
        isDeviceCheckedOut: isDeviceCheckedOut,
        orgId: orgId,
        deviceCheckedOutNote: deviceCheckedOutNote,
        onUserSelected: (selectedUserId) {
          _changeDeviceStatusAdminAndDeskstation(isDeviceCheckedOut, selectedUserId, deviceCheckedOutNote);
        },
      );
    },
  );
}
      
  /// Handles the submission of the check-in or check-out operation
  Future<void> _changeDeviceStatus(
      bool isDeviceBeingCheckedOut, String deviceCheckedOutNote) async {
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
        isDeviceBeingCheckedOut, // Pass the boolean to check-out or check-in the device
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
  

  
}

class CheckoutNoteDialog extends StatefulWidget {
  final bool isDeviceBeingCheckedOut;
  final String orgId;
  final bool isAdminOrDeskstation;
  final ValueChanged<String> onSubmit; // Callback with the entered note

  const CheckoutNoteDialog({
    super.key,
    required this.isDeviceBeingCheckedOut,
    required this.orgId,
    required this.isAdminOrDeskstation,
    required this.onSubmit,
  });

  @override
  _CheckoutNoteDialogState createState() => _CheckoutNoteDialogState();
}

class _CheckoutNoteDialogState extends State<CheckoutNoteDialog> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Please Leave a Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please describe why you are checking out this device',
          ),
          TextField(
            controller: _noteController,
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
            // Get the note from the text field
            final note = _noteController.text;
            Navigator.of(context).pop(); // Close the dialog
            widget.onSubmit(note); // Pass the note back to the caller
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Check Out Device'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Just close the dialog
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
  }
}


class UserListDialog extends StatefulWidget {
  final bool isDeviceCheckedOut;
  final String orgId;
  final String deviceCheckedOutNote;
  final ValueChanged<String> onUserSelected; // Callback with the selected userId

  const UserListDialog({
    super.key,
    required this.isDeviceCheckedOut,
    required this.orgId,
    required this.deviceCheckedOutNote,
    required this.onUserSelected,
  });

  @override
  _UserListDialogState createState() => _UserListDialogState();
}

class _UserListDialogState extends State<UserListDialog> {
  late TextEditingController _userSearchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userSearchController = TextEditingController();
    _userSearchController.addListener(() {
      setState(() {
        _searchQuery = _userSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.isDeviceCheckedOut
          ? 'Confirm Check-out User'
          : 'Confirm Check-in User'),
      content: Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
        builder: (context, firestoreReadService, orgSelectorChangeNotifier, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isDeviceCheckedOut
                    ? 'Select the user to check-out this device.'
                    : 'Select the user to check-in this device.',
              ),
              TextField(
                controller: _userSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search User',
                  prefixIcon: Icon(Icons.search),
                ),
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
                  final List<DocumentSnapshot> orgMemberDocs = snapshot.data ?? [];
                  final filteredDocs = orgMemberDocs.where((doc) {
                    final name = doc['orgMemberDisplayName']
                        .toString()
                        .toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredDocs.isNotEmpty) {
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: filteredDocs.map((orgMemberDoc) {
                            return ListTile(
                              title: Text(orgMemberDoc['orgMemberDisplayName']),
                              subtitle: Text(orgMemberDoc['orgMemberEmail']),
                              onTap: () {
                                widget.onUserSelected(orgMemberDoc.id);
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
                },
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog (or add additional logic)
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
  }
}

