// device_checkout_service.dart

import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/services/firestoreService.dart';

class DeviceCheckoutService {
  final FirestoreService firestoreService;

  DeviceCheckoutService({required this.firestoreService});

  Future<void> handleDeviceCheckout(
    BuildContext context,
    String deviceSerialNumber,
    String orgUid,
  ) async {
    if (deviceSerialNumber.isNotEmpty) {
      try {
        if (!await firestoreService.doesDeviceExistInFirestore(
            deviceSerialNumber, orgUid)) {
          await firestoreService.createDeviceInFirestore(
              deviceSerialNumber, orgUid);
          await firestoreService.updateDeviceCheckoutStatusInFirestore(
              deviceSerialNumber, orgUid, true);

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
          await firestoreService.updateDeviceCheckoutStatusInFirestore(
              deviceSerialNumber, orgUid, !isCheckedOut);

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
