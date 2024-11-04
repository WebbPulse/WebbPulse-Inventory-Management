import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import '../../providers/org_selector_change_notifier.dart';

import '../../providers/authentication_change_notifier.dart';

/// A button widget for deleting a device
class DeleteDeviceButton extends StatefulWidget {
  const DeleteDeviceButton({
    super.key,
    required this.deviceId, // The device data to be deleted
  });

  final String deviceId; // Device data passed as a parameter

  @override
  State<DeleteDeviceButton> createState() => _DeleteDeviceButtonState();
}

class _DeleteDeviceButtonState extends State<DeleteDeviceButton> {
  var _isLoading = false; // Loading state to show progress indicator

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Method to handle the delete device operation
  void _onPressed() async {
    final orgSelectorProvider = Provider.of<OrgSelectorChangeNotifier>(context,
        listen: false); // Get the current organization ID
    final firebaseFunctions = Provider.of<FirebaseFunctions>(context,
        listen: false); // Firebase Functions provider

    setState(() {
      _isLoading = true; // Set loading state to true during the operation
    });

    try {
      await firebaseFunctions.httpsCallable('delete_device_callable').call({
        'orgId': orgSelectorProvider.orgId, // Pass organization ID
        'deviceId': widget.deviceId, // Pass device ID
      });
      // Show success message when the device is deleted
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Device deleted successfully');
    } catch (e) {
      // Show error message if the operation fails
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to delete device: $e');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state after the operation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FirebaseFunctions, OrgSelectorChangeNotifier,
            AuthenticationChangeNotifier>(
        builder: (context, firebaseFunctions, orgSelectorChangeNotifier,
            authenticationChangeNotifier, child) {
      return ElevatedButton.icon(
        onPressed:
            _isLoading ? null : _onPressed, // Disable button when loading
        icon: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator if loading
            : const Icon(Icons.delete), // Delete icon for the button
        label: Wrap(children: [
          Text(
            'Delete Device',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold), // Button label
          ),
        ]),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.red, // Background color when disabled
          backgroundColor: Colors.red, // Background color
          padding: const EdgeInsets.all(16.0),
        ),
      );
    });
  }
}
