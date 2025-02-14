import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_checkout_service.dart';
import '../../providers/org_selector_change_notifier.dart';
import '../../providers/firestore_read_service.dart';
import '../../providers/authentication_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/checkout_note_dialog.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/checkout_user_list_dialog.dart';

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
                if (isAdminOrDeskstation) {
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
      return CheckoutUserListDialog(
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



