// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'firestore_read_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../helpers/async_context_helpers.dart';

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
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        ///if device does not exist in firestore, create it and check it out
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
            "isDeviceCheckedOut": true,
            "deviceCheckedOutBy": deviceCheckedOutBy,
          });

          await AsyncContextHelpers.showSnackBarIfMounted(
              context, 'Device added to organization and checked out!');
        } else {
          ///if device exists, check it in/out
          bool isDeviceCheckedOut = await firestoreService
              .isDeviceCheckedOutInFirestore(deviceSerialNumber, orgId);

          if (isDeviceCheckedOut) {
            ///if device is checked out, check it in
            await firebaseFunctions
                .httpsCallable('update_device_checkout_status_callable')
                .call({
              "deviceSerialNumber": deviceSerialNumber,
              "orgId": orgId,
              "isDeviceCheckedOut": false,
              "deviceCheckedOutBy": '',
            });
          } else {
            ///if device is checked in, check it out

            await firebaseFunctions
                .httpsCallable('update_device_checkout_status_callable')
                .call({
              "deviceSerialNumber": deviceSerialNumber,
              "orgId": orgId,
              "isDeviceCheckedOut": true,
              "deviceCheckedOutBy": deviceCheckedOutBy,
            });
          }

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
