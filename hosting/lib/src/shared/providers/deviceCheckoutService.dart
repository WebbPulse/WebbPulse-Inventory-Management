// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'firestoreService.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../helpers/asyncContextHelpers.dart';

class DeviceCheckoutService {
  final FirestoreService firestoreService;
  final FirebaseFunctions firebaseFunctions;
  DeviceCheckoutService(
      {required this.firestoreService, required this.firebaseFunctions});

  Future<void> handleDeviceCheckout(
    BuildContext context,
    String deviceSerialNumber,
    String orgId,
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        ///if device does not exist in firestore, create it and check it out
        if (!await firestoreService.doesDeviceExistInFirestore(
            deviceSerialNumber, orgId)) {
          await firebaseFunctions.httpsCallable('create_device_callable').call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
          });

          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
            "isDeviceCheckedOut": true,
          });

          await AsyncContextHelpers.showSnackBarIfMounted(
              context, 'Device added to organization and checked out!');
        } else {
          ///if device exists, check it in/out
          bool isDeviceCheckedOut = await firestoreService
              .isDeviceCheckedOutInFirestore(deviceSerialNumber, orgId);
          await firebaseFunctions
              .httpsCallable('update_device_checkout_status_callable')
              .call({
            "deviceSerialNumber": deviceSerialNumber,
            "orgId": orgId,
            "isDeviceCheckedOut": !isDeviceCheckedOut,
          });

          ///ensure context is mounted before showing snackbar
          await AsyncContextHelpers.showSnackBarIfMounted(
              context,
              isDeviceCheckedOut
                  ? 'Device checked in!'
                  : 'Device checked out!');
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
