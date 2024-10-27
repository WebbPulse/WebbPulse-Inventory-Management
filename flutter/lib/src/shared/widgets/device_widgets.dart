import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html; // Universal web support
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/device_checkout_service.dart';
import '../providers/org_selector_change_notifier.dart';
import '../providers/firestore_read_service.dart';
import '../providers/authentication_change_notifier.dart';

import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';

/// Widget that displays a list of devices and allows filtering by serial number or status
class DeviceList extends StatelessWidget {
  DeviceList({
    super.key,
    required this.devicesDocs,
  });

  final List<DocumentSnapshot>
      devicesDocs; // List of device documents from Firestore
  final ValueNotifier<String> _searchQuery =
      ValueNotifier<String>(''); // Notifier for search query

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgSelectorChangeNotifier>(
      builder: (context, orgSelectorProvider, child) {
        return Column(
          children: [
            /// Search field for filtering devices
            SerialSearchTextField(searchQuery: _searchQuery),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, child) {
                  final lowerCaseQuery =
                      query.toLowerCase(); // Convert query to lowercase

                  // Filter devices based on serial number or check-out status
                  final filteredDevices = devicesDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Convert boolean check-out status to a readable format
                    final isDeviceCheckedOut =
                        data['isDeviceCheckedOut'] == true
                            ? 'checked out'
                            : 'checked in';
                    final deviceSerialNumber =
                        (data['deviceSerialNumber'] ?? '')
                            .toString()
                            .toLowerCase();

                    // Check if the device matches the search query
                    return deviceSerialNumber.contains(lowerCaseQuery) ||
                        isDeviceCheckedOut.contains(lowerCaseQuery);
                  }).toList();

                  // Display the filtered devices
                  return filteredDevices.isNotEmpty
                      ? LayoutBuilder(builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth * 0.95,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredDevices.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> deviceData =
                                    filteredDevices[index].data()
                                        as Map<String, dynamic>;

                                return DeviceCard(
                                  deviceData: deviceData,
                                );
                              },
                            ),
                          );
                        })
                      : const Center(child: Text('No devices found'));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for the search input field, used to filter devices by serial number
class SerialSearchTextField extends StatefulWidget {
  final ValueNotifier<String> searchQuery;

  const SerialSearchTextField({super.key, required this.searchQuery});

  @override
  SerialSearchTextFieldState createState() => SerialSearchTextFieldState();
}

class SerialSearchTextFieldState extends State<SerialSearchTextField> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(); // Controller for the search field
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController, // Binds controller to the search field
        decoration: InputDecoration(
          labelText: 'Search by Serial',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear(); // Clear the input field
              widget.searchQuery.value = ''; // Reset the search query
            },
          ),
        ),
        onChanged: (value) {
          widget.searchQuery.value =
              value; // Update the search query on input change
        },
      ),
    );
  }
}

/// Widget to represent each individual device card in the list
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.deviceData,
  });

  final Map<String, dynamic> deviceData; // Data for the specific device

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String deviceId = deviceData['deviceId']; // Unique ID for the device
    final String deviceSerialNumber =
        deviceData['deviceSerialNumber']; // Device serial number
    final bool deviceDeleted =
        deviceData['deviceDeleted'] ?? false; // Check if device is deleted

    // Skip rendering if the device has been marked as deleted
    if (deviceDeleted) {
      return const SizedBox.shrink();
    }

    return AuthClaimChecker(builder: (context, userClaims) {
      return Consumer4<FirestoreReadService, DeviceCheckoutService,
          OrgSelectorChangeNotifier, FirebaseFunctions>(
        builder: (context, firestoreService, deviceCheckoutService,
            orgSelectorChangeNotifier, firebaseFunctions, child) {
          // Stream the device data for updates
          return StreamBuilder(
            stream: firestoreService.getOrgDeviceDocument(
                deviceId, orgSelectorChangeNotifier.orgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // Show loading indicator
              } else if (snapshot.hasError) {
                return const Text(
                    'Error loading devices'); // Show error message
              }

              final deviceData = snapshot.data?.data()
                  as Map<String, dynamic>; // Fetch device data
              final orgMemberId = deviceData[
                  'deviceCheckedOutBy']; // ID of the member who checked out the device
              final orgId =
                  orgSelectorChangeNotifier.orgId; // Current organization ID

              // Stream the organization member data
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
                    } else if (!snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.data() == null) {
                      // If no member data is available, show a basic device card layout
                      return LayoutBuilder(builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return CustomCard(
                            theme: theme,
                            customCardLeading: null,
                            customCardTitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.devices,
                                      color: theme.colorScheme
                                          .secondary), // Device icon
                                  Wrap(
                                    children: [
                                      Text(deviceSerialNumber,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    runSpacing: 8,
                                    children: [
                                      DeviceCheckoutButton(
                                        deviceSerialNumber: deviceSerialNumber,
                                        isDeviceCheckedOut: deviceData[
                                            'isDeviceCheckedOut'], // Check-in/out button
                                      ),
                                      const SizedBox(width: 8),
                                      if (userClaims['org_admin_$orgId'] ==
                                          true)
                                        DeleteDeviceButton(
                                            deviceData:
                                                deviceData), // Delete button if the user is admin
                                    ],
                                  ),
                                ]),
                            customCardTrailing: null,
                            onTapAction: () {},
                          );
                        }
                        return CustomCard(
                          theme: theme,
                          customCardLeading: Icon(Icons.devices,
                              color:
                                  theme.colorScheme.secondary), // Device icon
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
                                                fontWeight: FontWeight
                                                    .bold)), // Display serial number
                                      ],
                                    ),
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
                                        isDeviceCheckedOut: deviceData[
                                            'isDeviceCheckedOut'], // Check-in/out button
                                      ),
                                      const SizedBox(width: 8),
                                      if (userClaims['org_admin_$orgId'] ==
                                          true)
                                        DeleteDeviceButton(
                                            deviceData:
                                                deviceData), // Admin delete button
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          customCardTrailing: null,
                          onTapAction: () {},
                        );
                      });
                    }

                    // Fetch the organization member data
                    Map<String, dynamic> orgMemberData =
                        snapshot.data?.data() as Map<String, dynamic>;

                    final Timestamp deviceCheckedOutAtTimestamp = deviceData[
                        'deviceCheckedOutAt']; // Timestamp for check-out date
                    final DateTime deviceCheckedOutAt =
                        deviceCheckedOutAtTimestamp
                            .toDate(); // Convert to DateTime
                    final String deviceCheckedOutAtFormatted =
                        DateFormat('yyyy-MM-dd kk:mm a')
                            .format(deviceCheckedOutAt); // Format the date

                    // Display the full device card with member and check-out details
                    return LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return CustomCard(
                          theme: theme,
                          customCardLeading: null,
                          customCardTitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.devices,
                                    color: theme
                                        .colorScheme.secondary), // Device icon
                                Wrap(
                                  children: [
                                    Text(deviceSerialNumber,
                                        style: const TextStyle(
                                            fontWeight: FontWeight
                                                .bold)), // Serial number
                                  ],
                                ),
                                Wrap(
                                  children: [
                                    Text('Checked Out By: ',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight
                                                .bold)), // Label for checked out by
                                    Text(orgMemberData['orgMemberDisplayName'],
                                        style: theme.textTheme
                                            .labelSmall), // Member's name
                                  ],
                                ),
                                Wrap(
                                  children: [
                                    Text('Checked Out On: ',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight
                                                .bold)), // Label for checked out date
                                    Text(deviceCheckedOutAtFormatted,
                                        style: theme.textTheme
                                            .labelSmall), // Date of check-out
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  runSpacing: 8,
                                  children: [
                                    DeviceCheckoutButton(
                                      deviceSerialNumber: deviceSerialNumber,
                                      isDeviceCheckedOut: deviceData[
                                          'isDeviceCheckedOut'], // Check-in/out button
                                    ),
                                    const SizedBox(width: 8),
                                    if (userClaims['org_admin_$orgId'] == true)
                                      DeleteDeviceButton(
                                          deviceData:
                                              deviceData), // Admin delete button
                                  ],
                                ),
                              ]),
                          customCardTrailing: null,
                          onTapAction: () {},
                        );
                      }
                      return CustomCard(
                        theme: theme,
                        customCardLeading: Icon(Icons.devices,
                            color: theme.colorScheme.secondary), // Device icon
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
                                                fontWeight: FontWeight
                                                    .bold)), // Serial number
                                      ],
                                    ),
                                    Wrap(
                                      children: [
                                        Text('Checked Out By: ',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                    fontWeight: FontWeight
                                                        .bold)), // Label for checked out by
                                        Text(
                                            orgMemberData[
                                                'orgMemberDisplayName'], // Member's display name
                                            style: theme.textTheme.labelSmall),
                                      ],
                                    ),
                                    Wrap(
                                      children: [
                                        Text('Checked Out On: ',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                    fontWeight: FontWeight
                                                        .bold)), // Label for check-out date
                                        Text(deviceCheckedOutAtFormatted,
                                            style: theme.textTheme
                                                .labelSmall), // Date of check-out
                                      ],
                                    )
                                  ]),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    DeviceCheckoutButton(
                                      deviceSerialNumber: deviceSerialNumber,
                                      isDeviceCheckedOut: deviceData[
                                          'isDeviceCheckedOut'], // Check-in/out button
                                    ),
                                    const SizedBox(width: 8),
                                    if (userClaims['org_admin_$orgId'] == true)
                                      DeleteDeviceButton(
                                          deviceData:
                                              deviceData), // Admin delete button
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        customCardTrailing: null,
                        onTapAction: () {},
                      );
                    });
                  });
            },
          );
        },
      );
    });
  }
}

class DeviceCheckoutButton extends StatefulWidget {
  final String deviceSerialNumber; // The serial number of the device
  final bool isDeviceCheckedOut; // Whether the device is currently checked out

  const DeviceCheckoutButton({
    super.key,
    required this.deviceSerialNumber,
    required this.isDeviceCheckedOut,
  });

  @override
  DeviceCheckoutButtonState createState() => DeviceCheckoutButtonState();
}

class DeviceCheckoutButtonState extends State<DeviceCheckoutButton> {
  var _isLoading = false; // Flag to indicate if an operation is in progress
  late TextEditingController
      _userSearchController; // Controller for the user search field
  String _searchQuery = ''; // Search query for filtering users

  @override
  void initState() {
    super.initState();
    _userSearchController =
        TextEditingController(); // Initialize the search controller
    _userSearchController.addListener(
        _onSearchChanged); // Listen for changes in the search field
  }

  @override
  void dispose() {
    _userSearchController.dispose(); // Dispose the search controller
    super.dispose();
  }

  /// Updates the search query when the text field changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _userSearchController.text;
    });
  }

  /// Handles the submission of the check-in or check-out operation
  void _onSubmit(bool checkOut) async {
    setState(() => _isLoading = true); // Set loading state
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckedOutBy =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
            .user!
            .uid;
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass the boolean to check-out or check-in the device
      );
    } catch (e) {
      // Handle errors if needed
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Handles the submission of check-in/check-out by admins or desk stations
  Future<void> _onSubmitAdminAndDeskstation(
      bool checkOut, String deviceCheckedOutBy) async {
    setState(() => _isLoading = true); // Set loading state
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass the boolean for check-in or check-out
      );
    } catch (e) {
      // Handle errors if needed
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Shows a dialog for admin or desk station users to select a user for check-in/check-out
  Future<void> _showAdminDialog(bool checkOut, String orgId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        ThemeData theme = Theme.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(checkOut
                  ? 'Confirm Check-out User'
                  : 'Confirm Check-in User'), // Title based on check-out or check-in
              content:
                  Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
                      builder: (context, firestoreReadService,
                          orgSelectorChangeNotifier, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkOut
                          ? 'Select the user to check-out this device.'
                          : 'Select the user to check-in this device.', // Instruction text
                    ),
                    TextField(
                      controller:
                          _userSearchController, // Search field for users
                      decoration: const InputDecoration(
                        labelText: 'Search User',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value; // Update search query
                        });
                      },
                    ),
                    StreamBuilder<List<DocumentSnapshot>>(
                        stream: firestoreReadService.getOrgMembersDocuments(
                            orgSelectorChangeNotifier
                                .orgId), // Stream to fetch organization members
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child:
                                    CircularProgressIndicator()); // Show loading indicator
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text(
                                    'Error loading users')); // Show error message
                          }
                          final List<DocumentSnapshot> orgMemberDocs =
                              snapshot.data!;

                          // Filter members based on search query
                          final filteredDocs = orgMemberDocs.where((doc) {
                            final name = doc['orgMemberDisplayName']
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                          if (filteredDocs.isNotEmpty) {
                            return Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: filteredDocs.map((orgMemberDoc) {
                                    return ListTile(
                                      title: Text(orgMemberDoc[
                                          'orgMemberDisplayName']), // Display member name
                                      subtitle: Text(orgMemberDoc[
                                          'orgMemberEmail']), // Display member email
                                      onTap: () {
                                        _onSubmitAdminAndDeskstation(
                                          checkOut,
                                          orgMemberDoc
                                              .id, // Submit with selected member
                                        );
                                        Navigator.of(context)
                                            .pop(); // Close dialog
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          } else {
                            return const Column(
                              children: [
                                SizedBox(
                                  height: 16,
                                ),
                                Center(
                                  child: Text(
                                      'No users found.'), // Message when no users match search
                                ),
                              ],
                            );
                          }
                        }),
                  ],
                );
              }),
              actions: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.surface.withOpacity(0.95),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.all(16.0),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'), // Button to go back
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Fetch the current theme
    return AuthClaimChecker(builder: (context, userClaims) {
      final orgId =
          Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;

      // Check if the user is an admin or desk station for this organization
      bool isAdminOrDeskstation = (userClaims['org_admin_$orgId'] == true) ||
          (userClaims['org_deskstation_$orgId'] == true);

      return ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  if (isAdminOrDeskstation && !widget.isDeviceCheckedOut) {
                    _showAdminDialog(
                        true, orgId); // Show dialog if admin or desk station
                  } else {
                    _onSubmit(!widget
                        .isDeviceCheckedOut); // Submit the action (check-in or check-out)
                  }
                },
          icon: _isLoading
              ? const CircularProgressIndicator()
              : Icon(widget.isDeviceCheckedOut
                  ? Icons.logout
                  : Icons.login), // Icon for check-in/check-out
          label: Text(widget.isDeviceCheckedOut
              ? 'Check-in Device'
              : 'Check-out Device'), // Label for the button
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ));
    });
  }
}

/// A button widget for deleting a device
class DeleteDeviceButton extends StatefulWidget {
  const DeleteDeviceButton({
    super.key,
    required this.deviceData, // The device data to be deleted
  });

  final Map<String, dynamic> deviceData; // Device data passed as a parameter

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
      String deviceId = widget.deviceData[
          'deviceId']; // Retrieve the device ID from the passed data
      await firebaseFunctions.httpsCallable('delete_device_callable').call({
        'orgId': orgSelectorProvider.orgId, // Pass organization ID
        'deviceId': deviceId, // Pass device ID
      });
      // Show success message when the device is deleted
      AsyncContextHelpers.showSnackBarIfMounted(
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

/// A dialog widget to add a new device, supporting CSV upload or manual input
class AddDeviceAlertDialog extends StatefulWidget {
  const AddDeviceAlertDialog({super.key});

  @override
  AddDeviceAlertDialogState createState() => AddDeviceAlertDialogState();
}

class AddDeviceAlertDialogState extends State<AddDeviceAlertDialog> {
  late TextEditingController
      _deviceSerialNumberController; // Controller for device serial number input
  var _isLoading = false; // Loading state for submit action
  final String csvTemplate =
      "Device Serial Number\nAAAA-AAAA-AAAA\nBBBB-BBBB-BBBB"; // CSV template for downloading

  @override
  void initState() {
    super.initState();
    _deviceSerialNumberController =
        TextEditingController(); // Initialize the text controller
  }

  @override
  void dispose() {
    _deviceSerialNumberController
        .dispose(); // Dispose of the controller when the widget is destroyed
    super.dispose();
  }

  /// Method to download the CSV template for both web and mobile platforms
  Future<void> downloadCSV() async {
    if (kIsWeb) {
      // Web platform: Trigger CSV download using HTML anchor element
      downloadCSVForWeb();
    } else {
      // Mobile/Desktop platform: Save CSV to file and notify user
      await downloadCSVForMobile();
    }
  }

  /// Method to download CSV on web platforms using `universal_html`
  void downloadCSVForWeb() {
    final bytes = utf8.encode(csvTemplate); // Convert CSV content to bytes
    final blob = html.Blob([bytes], 'text/csv'); // Create a Blob for the CSV

    // Create an anchor element to trigger the download
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "device_template.csv") // Set the file name
      ..click(); // Trigger the download
    html.Url.revokeObjectUrl(url); // Revoke the URL to free up memory
  }

  /// Method to download CSV for mobile and desktop platforms
  Future<void> downloadCSVForMobile() async {
    // Request storage permissions (only for Android/iOS)
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Get the directory to save the CSV file
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        String filePath =
            '${directory.path}/user_template.csv'; // Define the file path

        // Write the CSV content to the file
        io.File file = io.File(filePath);
        await file.writeAsString(csvTemplate);

        // Notify user that the file has been saved
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'CSV Template saved to $filePath');
      } else {
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to get storage directory');
      }
    } else {
      AsyncContextHelpers.showSnackBarIfMounted(context, 'Permission denied');
    }
  }

  /// Method to handle the submission of device serial numbers
  Future<void> _submitDeviceSerialNumbers(
      List<String> deviceSerialNumbers) async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      await firebaseFunctions.httpsCallable('create_devices_callable').call({
        "deviceSerialNumbers": deviceSerialNumbers, // List of serial numbers
        "orgId": orgSelectorProvider.orgId, // Organization ID
      });
      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Devices created successfully'); // Show success message
      AsyncContextHelpers.popContextIfMounted(context); // Close the dialog
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to create Devices: $e'); // Show error message
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  /// Handle submission of a single device serial number entered manually
  void _onSubmitSingleEmail() async {
    final deviceSerialNumber = _deviceSerialNumberController.text;
    if (deviceSerialNumber.isNotEmpty) {
      await _submitDeviceSerialNumbers(
          [deviceSerialNumber]); // Submit the serial number
    }
  }

  /// Method to handle file selection and parsing of CSV content
  void _onCsvFileSelected() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Limit the file type to custom (CSV)
      allowedExtensions: ['csv'], // Allow only CSV files
    );

    if (result != null) {
      String content = '';

      // Handle file content differently for web and mobile platforms
      if (kIsWeb) {
        // Web: Get content from file bytes
        final file = result.files.first;
        content = utf8.decode(file.bytes!);
      } else {
        // Mobile/Desktop: Get content from file path
        final path = result.files.single.path;
        if (path != null) {
          final file = io.File(path);
          content = await file.readAsString();
        }
      }

      // Split the CSV content by line breaks and process it
      List<String> lines = content.split(RegExp(r'[\r\n]+'));

      // Skip the first line (header) and process remaining lines
      if (lines.isNotEmpty) {
        lines = lines.sublist(1); // Remove header row
      }

      // Extract the device serial numbers, excluding empty lines
      List<String> deviceSerialNumbers = lines
          .map((line) => line.trim()) // Trim each line
          .where((line) => line.isNotEmpty) // Exclude empty lines
          .toList();

      // Submit the device serial numbers if the list is not empty
      if (deviceSerialNumbers.isNotEmpty) {
        await _submitDeviceSerialNumbers(deviceSerialNumbers);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Get current theme data
    return AlertDialog(
      title: const Text('Add New Device'), // Dialog title
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 500), // Set max width for dialog
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimize size based on content
            children: [
              Column(
                children: [
                  const Text(
                    'Add a new device to this organization', // Instruction text
                  ),
                  TextField(
                    controller:
                        _deviceSerialNumberController, // Input for device serial number
                    decoration: const InputDecoration(
                      labelText: 'Device Serial Number',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed:
              _isLoading ? null : _onSubmitSingleEmail, // Submit single device
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.add), // Add icon
          label: const Text('Add Device'), // Button label
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed:
              _isLoading ? null : _onCsvFileSelected, // Submit devices via CSV
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.upload_file), // CSV upload icon
          label: const Text('Add Devices from CSV'), // Button label
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () async {
            await downloadCSV(); // Trigger download of CSV template
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.download), // Download icon
          label: const Text('Download CSV Template'), // Button label
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.arrow_back), // Back icon
          label: const Text('Go Back'), // Button label
        ),
      ],
    );
  }
}
