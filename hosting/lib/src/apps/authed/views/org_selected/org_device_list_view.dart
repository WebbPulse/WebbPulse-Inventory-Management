import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart'; // Importing user-related widgets
import 'package:webbpulse_inventory_management/src/shared/widgets/org_widgets.dart'; // Importing organization-related widgets
import 'package:webbpulse_inventory_management/src/shared/widgets/device_widgets.dart'; // Importing device-related widgets

/// OrgDeviceListView displays a list of devices for a selected organization.
/// It also provides functionality for adding new devices to the organization.
class OrgDeviceListView extends StatelessWidget {
  const OrgDeviceListView({super.key});

  // Route name for navigation
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Get the current theme

    return Scaffold(
      // AppBar with the organization's name and an option to add new devices
      appBar: OrgNameAppBar(
        titleSuffix: 'Devices', // Displays "Devices" next to the org name
        actions: [
          // Button to trigger the "Add New Device" dialog
          ElevatedButton.icon(
            onPressed: () {
              // Show dialog to add a new device
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AddDeviceAlertDialog(); // Add device dialog
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.all(16.0),
            ),
            label: const Text('Add New Device'),
            icon: const Icon(Icons.add), // Icon for the button
          )
        ],
      ),

      // Drawer for navigation
      drawer: const AuthedDrawer(),

      // Main content displaying the list of devices in the organization
      body: Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(
        builder: (context, orgSelectorProvider, firestoreService, child) {
          // StreamBuilder to listen for real-time updates on the list of devices
          return StreamBuilder<List<DocumentSnapshot>>(
            stream: firestoreService.getOrgDevicesDocuments(
                orgSelectorProvider.orgId), // Fetch devices by organization ID
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // Show loading indicator while waiting for data
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text(
                        'Error loading devices')); // Display error if there's an issue
              }

              final List<DocumentSnapshot> devicesDocs =
                  snapshot.data!; // Get the list of device documents

              // Display the list of devices
              return DeviceList(
                devicesDocs: devicesDocs,
              );
            },
          );
        },
      ),
    );
  }
}
