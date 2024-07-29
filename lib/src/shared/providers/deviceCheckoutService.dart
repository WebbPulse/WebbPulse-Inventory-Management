// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/providers/firestoreService.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/shared/helpers/asyncContextHelpers.dart';

class DeviceCheckoutService {
  final FirestoreService firestoreService;
  final FirebaseFunctions firebaseFunctions;
  DeviceCheckoutService(
      {required this.firestoreService, required this.firebaseFunctions});

  Future<void> handleDeviceCheckout(
    BuildContext context,
    String deviceSerialNumber,
    String orgUid,
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        ///if device does not exist in firestore, create it and check it out
        if (!await firestoreService.doesDeviceExistInFirestore(
            deviceSerialNumber, orgUid)) {
          await firebaseFunctions.httpsCallable('create_device_callable').call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgUid": orgUid,
          });

          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgUid": orgUid,
            "isCheckedOut": true,
          });

          await AsyncContextHelpers.showSnackBarIfMounted(
              context, 'Device added to organization and checked out!');
        } else {
          ///if device exists, check it in/out
          bool isCheckedOut = await firestoreService
              .isDeviceCheckedOutInFirestore(deviceSerialNumber, orgUid);
          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgUid": orgUid,
            "isCheckedOut": !isCheckedOut,
          });

          ///ensure context is mounted before showing snackbar
          await AsyncContextHelpers.showSnackBarIfMounted(context,
              isCheckedOut ? 'Device checked in!' : 'Device checked out!');
        }
      } catch (e) {
        ///ensure context is mounted before showing snackbar
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to check in/out device: $e');
      }
    } else {
      AsyncContextHelpers.showSnackBar(context, 'Please enter a serial number');
    }
  }
}
