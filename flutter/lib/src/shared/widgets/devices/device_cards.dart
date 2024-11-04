import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/device_checkout_service.dart';
import '../../providers/org_selector_change_notifier.dart';
import '../../providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/device_checkout_button.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/devices/device_delete_button.dart';

import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';

class DeviceCardDesktop extends StatelessWidget {
  const DeviceCardDesktop({
    super.key,
    required this.deviceData,
  });

  final Map<String, dynamic> deviceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String deviceId =
        deviceData['deviceId']; // Retrieve the device ID from the passed data
    final String deviceSerialNumber =
        deviceData['deviceSerialNumber']; // Device serial number
    final bool deviceDeleted =
        deviceData['deviceDeleted'] ?? false; // Check if device is deleted
    final String orgMemberId = deviceData[
        'deviceCheckedOutBy']; // ID of the member who checked out the device
    final bool isDeviceCheckedOut =
        deviceData['isDeviceCheckedOut']; // Check-in/out button
    final String deviceCheckedOutNote =
        deviceData['deviceCheckedOutNote'] ?? ''; // Device note

    final Timestamp deviceCheckedOutAtTimestamp =
        deviceData['deviceCheckedOutAt'] ??
            Timestamp.now(); // Timestamp of check-out
    final DateTime deviceCheckedOutAt =
        deviceCheckedOutAtTimestamp.toDate(); // Convert to DateTime
    final String deviceCheckedOutAtFormatted = DateFormat('yyyy-MM-dd kk:mm a')
        .format(deviceCheckedOutAt); // Format the date

    // Skip rendering if the device has been marked as deleted
    if (deviceDeleted) {
      return const SizedBox.shrink();
    } else {
      return Consumer4<FirestoreReadService, DeviceCheckoutService,
              OrgSelectorChangeNotifier, FirebaseFunctions>(
          builder: (context, firestoreService, deviceCheckoutService,
              orgSelectorChangeNotifier, firebaseFunctions, child) {
        return StreamBuilder<DocumentSnapshot?>(
            stream: firestoreService.getOrgMemberDocument(
                orgSelectorChangeNotifier.orgId, orgMemberId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // Show loading indicator
              } else if (snapshot.hasError) {
                return const Text(
                    'Error loading org member data'); // Show error message
              } else {
                // If no member data is available, show a basic device card layout
                // Fetch the organization member data
                Map<String, dynamic> orgMemberData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                return AuthClaimChecker(
                  builder: (context, userClaims) {
                    return CustomCard(
                      theme: theme,
                      customCardLeading: Icon(Icons.devices,
                          color: theme.colorScheme.secondary),
                      customCardTitle: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  children: [
                                    Text(deviceSerialNumber,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (isDeviceCheckedOut) ...[
                                  Wrap(
                                    children: [
                                      Text('Checked Out By: ',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text(
                                          orgMemberData['orgMemberDisplayName'],
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                  Wrap(
                                    children: [
                                      Text('Checked Out On: ',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text(deviceCheckedOutAtFormatted,
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                  Wrap(
                                    children: [
                                      Text('Checkout Note: ',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text(deviceCheckedOutNote,
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  DeviceCheckoutButton(
                                    deviceSerialNumber: deviceSerialNumber,
                                  ),
                                  const SizedBox(width: 8),
                                  if (userClaims[
                                          'org_admin_${orgSelectorChangeNotifier.orgId}'] ==
                                      true)
                                    DeleteDeviceButton(deviceId: deviceId),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      customCardTrailing: null,
                      onTapAction: () {},
                    );
                  },
                );
              }
            });
      });
    }
  }
}

class DeviceCardMobile extends StatelessWidget {
  const DeviceCardMobile({
    super.key,
    required this.deviceData,
  });

  final Map<String, dynamic> deviceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String deviceId =
        deviceData['deviceId']; // Retrieve the device ID from the passed data
    final String deviceSerialNumber =
        deviceData['deviceSerialNumber']; // Device serial number
    final bool deviceDeleted =
        deviceData['deviceDeleted'] ?? false; // Check if device is deleted
    final String orgMemberId = deviceData[
        'deviceCheckedOutBy']; // ID of the member who checked out the device
    final bool isDeviceCheckedOut =
        deviceData['isDeviceCheckedOut']; // Check-in/out button
    final String deviceCheckedOutNote =
        deviceData['deviceCheckedOutNote'] ?? ''; // Device note

    final Timestamp deviceCheckedOutAtTimestamp =
        deviceData['deviceCheckedOutAt'] ??
            Timestamp.now(); // Timestamp of check-out
    final DateTime deviceCheckedOutAt =
        deviceCheckedOutAtTimestamp.toDate(); // Convert to DateTime
    final String deviceCheckedOutAtFormatted = DateFormat('yyyy-MM-dd kk:mm a')
        .format(deviceCheckedOutAt); // Format the date

    // Skip rendering if the device has been marked as deleted
    if (deviceDeleted) {
      return const SizedBox.shrink();
    }
    return Consumer4<FirestoreReadService, DeviceCheckoutService,
            OrgSelectorChangeNotifier, FirebaseFunctions>(
        builder: (context, firestoreService, deviceCheckoutService,
            orgSelectorChangeNotifier, firebaseFunctions, child) {
      return StreamBuilder<DocumentSnapshot?>(
          stream: firestoreService.getOrgMemberDocument(
              orgSelectorChangeNotifier.orgId, orgMemberId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Show loading indicator
            } else if (snapshot.hasError) {
              return const Text(
                  'Error loading org member data'); // Show error message
            } else {
              // If no member data is available, show a basic device card layout
              // Fetch the organization member data
              Map<String, dynamic> orgMemberData =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};
              return AuthClaimChecker(
                builder: (context, userClaims) {
                  return CustomCard(
                    theme: theme,
                    customCardLeading: null,
                    customCardTitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.devices, color: theme.colorScheme.secondary),
                        Wrap(
                          children: [
                            Text(deviceSerialNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (isDeviceCheckedOut) ...[
                          Wrap(
                            children: [
                              Text('Checked Out By: ',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(orgMemberData['orgMemberDisplayName'],
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                          Wrap(
                            children: [
                              Text('Checked Out On: ',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(deviceCheckedOutAtFormatted,
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                          Wrap(
                            children: [
                              Text('Checkout Note: ',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(deviceCheckedOutNote,
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.start,
                          runSpacing: 8,
                          children: [
                            DeviceCheckoutButton(
                              deviceSerialNumber: deviceSerialNumber,
                            ),
                            const SizedBox(width: 8),
                            if (userClaims[
                                    'org_admin_${orgSelectorChangeNotifier.orgId}'] ==
                                true)
                              DeleteDeviceButton(deviceId: deviceId),
                          ],
                        ),
                      ],
                    ),
                    customCardTrailing: null,
                    onTapAction: () {},
                  );
                },
              );
            }
          });
    });
  }
}
