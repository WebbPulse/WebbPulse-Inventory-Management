// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/services/firestoreService.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DeviceCheckoutService {
  final FirestoreService firestoreService;

  DeviceCheckoutService({required this.firestoreService});
  final FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;

  Future<void> handleDeviceCheckout(
    BuildContext context,
    String deviceSerialNumber,
    String orgUid,
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
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

          ///ensure context is mounted before showing snackbar
          while (context.mounted == false) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (context.mounted) {
            _showSnackBar(
                context, 'Device added to organization and checked out!');
          }
        } else {
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
          while (context.mounted == false) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (context.mounted) {
            _showSnackBar(context,
                isCheckedOut ? 'Device checked in!' : 'Device checked out!');
          }
        }
      } catch (e) {
        ///ensure context is mounted before showing snackbar
        while (context.mounted == false) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (context.mounted) {
          _showSnackBar(context, 'Failed to check in/out device: $e');
        }
      }
    } else {
      _showSnackBar(context, 'Please enter a serial number');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
