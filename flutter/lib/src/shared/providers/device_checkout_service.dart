import 'package:flutter/material.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';

import 'firestore_read_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/styling/styling_widgets.dart';

/// Service class for handling the check-in and check-out logic of devices
class DeviceCheckoutService {
  final FirestoreReadService
      firestoreService; // A service to read from Firestore
  final FirebaseFunctions firebaseFunctions; // Firebase Functions instance

  /// Constructor for initializing FirestoreReadService and FirebaseFunctions
  DeviceCheckoutService(
      {required this.firestoreService, required this.firebaseFunctions});

  /// Main method to handle device check-in and check-out
  Future<void> handleDeviceCheckout(
      BuildContext context,
      String deviceSerialNumber, // The serial number of the device
      String orgId, // The organization ID
      String deviceBeingCheckedBy, // The ID of the user checking out the device
      bool isDeviceBeingCheckedOut, // Boolean flag to check in or check out
      String deviceCheckedOutNote) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        // Retrieve the authentication state from the provider
        final authenticationChangeNotifier =
            Provider.of<AuthenticationChangeNotifier>(context, listen: false);

        /// If the device is not checked out by the current user, verify their permissions
        if (deviceBeingCheckedBy != authenticationChangeNotifier.user!.uid) {
          /// Retrieve the user's ID token to check claims for permissions
          IdTokenResult userIdTokenResult =
              await authenticationChangeNotifier.user!.getIdTokenResult();
          final userClaims = userIdTokenResult.claims;

          /// Check if the user has the right claims (admin or deskstation role) to check out devices for others
          if (userClaims!['org_admin_$orgId'] == false &&
              userClaims['org_deskstation_$orgId'] == false) {
            await AsyncContextHelpers.showSnackBarIfMounted(context,
                'You do not have permission to check out devices for other users in this organization');
            return; // Exit if user lacks necessary permissions
          }
        }

        /// If the device does not exist in Firestore, create the device and check it out
        if (!await firestoreService.doesDeviceExistInFirestore(
            deviceSerialNumber, orgId)) {
          await firebaseFunctions
              .httpsCallable('create_devices_callable')
              .call({
            "deviceSerialNumbers": [deviceSerialNumber],
            "orgId": orgId,
            "isDeviceCheckedOut": false,
          });

          /// Update the device's checkout status using Firebase Functions
          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
            "isDeviceBeingCheckedOut": isDeviceBeingCheckedOut,
            "deviceBeingCheckedBy": deviceBeingCheckedBy,
            "deviceCheckedOutNote": deviceCheckedOutNote
          });

          /// Show a message based on the action performed (check-in/check-out)
          String snackBarMessage = isDeviceBeingCheckedOut
              ? 'Device added to organization and checked out!'
              : 'Device added to organization and checked in!';

          await AsyncContextHelpers.showSnackBarIfMounted(
              context, snackBarMessage);
        } else {
          /// Handle the case where the device already exists in Firestore
          bool isDeviceCheckedOut = await firestoreService
              .isDeviceCheckedOutInFirestore(deviceSerialNumber, orgId);

          /// If the device is already checked out, prevent re-checking it out
          if (isDeviceBeingCheckedOut && isDeviceCheckedOut) {
            await AsyncContextHelpers.showSnackBarIfMounted(
                context, 'Device is already checked out!');
          }

          /// If the device is already checked in, prevent re-checking it in
          else if (!isDeviceBeingCheckedOut && !isDeviceCheckedOut) {
            await AsyncContextHelpers.showSnackBarIfMounted(
                context, 'Device is already checked in!');
          }

          /// Otherwise, proceed with updating the check-in/check-out status
          else {
            await firebaseFunctions
                .httpsCallable('update_device_checkout_status_callable')
                .call({
              "deviceSerialNumber": deviceSerialNumber,
              "orgId": orgId,
              "isDeviceBeingCheckedOut": isDeviceBeingCheckedOut,
              "deviceBeingCheckedBy": deviceBeingCheckedBy,
              "deviceCheckedOutNote": deviceCheckedOutNote
            });

            await AsyncContextHelpers.showSnackBarIfMounted(
                context,
                isDeviceBeingCheckedOut
                    ? 'Device checked out successfully!'
                    : 'Device checked in successfully!');
          }
        }
      } catch (e) {
        /// Catch any exceptions and show an error message if the process fails
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to check in/out device: $e');
      }
    } else {
      /// If no serial number is provided, show a prompt to enter it
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Please enter a serial number');
    }
  }
}
