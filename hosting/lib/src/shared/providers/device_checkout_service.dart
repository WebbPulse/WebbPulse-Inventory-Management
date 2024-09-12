// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'firestore_read_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../helpers/async_context_helpers.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceCheckoutService {
  final FirestoreReadService firestoreService;
  final FirebaseFunctions firebaseFunctions;
  DeviceCheckoutService(
      {required this.firestoreService, required this.firebaseFunctions});

  Future<void> handleDeviceCheckout(
    BuildContext context,
    String deviceSerialNumber,
    String orgId,
    String deviceCheckedOutBy,
    bool checkOut,
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        // Get the authentication and org selector change notifiers
        final authenticationChangeNotifier =
            Provider.of<AuthenticationChangeNotifier>(context, listen: false);

        // If the device is not checked out by the current user, check the user's claims to see if they have permission to check out devices for other users in the organization
        if (deviceCheckedOutBy != authenticationChangeNotifier.user!.uid) {
          // Await the user ID token result so we can check the user's claims
          IdTokenResult userIdTokenResult =
              await authenticationChangeNotifier.user!.getIdTokenResult();
          final userClaims = userIdTokenResult.claims;

          if (userClaims!['org_admin_$orgId'] == false &&
              userClaims['org_deskstation_$orgId'] == false) {
            await AsyncContextHelpers.showSnackBarIfMounted(context,
                'You do not have permission to check out devices for other users in this organization');
            return;
          }
        }

        // If device does not exist in Firestore, create it and check it out
        if (!await firestoreService.doesDeviceExistInFirestore(
            deviceSerialNumber, orgId)) {
          await firebaseFunctions.httpsCallable('create_device_callable').call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
            "isDeviceCheckedOut": false,
          });

          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
            "isDeviceCheckedOut": checkOut,
            "deviceCheckedOutBy": checkOut ? deviceCheckedOutBy : '',
          });

          // Update the SnackBar message based on the checkOut boolean value
          String snackBarMessage = checkOut
              ? 'Device added to organization and checked out!'
              : 'Device added to organization and checked in!';

          await AsyncContextHelpers.showSnackBarIfMounted(
              context, snackBarMessage);
        } else {
          // If device exists, handle check-in/check-out based on current state
          bool isDeviceCheckedOut = await firestoreService
              .isDeviceCheckedOutInFirestore(deviceSerialNumber, orgId);

          if (checkOut && isDeviceCheckedOut) {
            // If trying to check out but it's already checked out
            await AsyncContextHelpers.showSnackBarIfMounted(
                context, 'Device is already checked out!');
          } else if (!checkOut && !isDeviceCheckedOut) {
            // If trying to check in but it's already checked in
            await AsyncContextHelpers.showSnackBarIfMounted(
                context, 'Device is already checked in!');
          } else {
            // Update the checkout status
            await firebaseFunctions
                .httpsCallable('update_device_checkout_status_callable')
                .call({
              "deviceSerialNumber": deviceSerialNumber,
              "orgId": orgId,
              "isDeviceCheckedOut": checkOut,
              "deviceCheckedOutBy": checkOut ? deviceCheckedOutBy : '',
            });

            await AsyncContextHelpers.showSnackBarIfMounted(
                context,
                checkOut
                    ? 'Device checked out successfully!'
                    : 'Device checked in successfully!');
          }
        }
      } catch (e) {
        // Ensure context is mounted before showing snackbar
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to check in/out device: $e');
      }
    } else {
      AsyncContextHelpers.showSnackBar(context, 'Please enter a serial number');
    }
  }
}
