import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:universal_html/html.dart' as html; // Universal web support
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import '../../providers/org_selector_change_notifier.dart';

import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';

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
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'CSV Template saved to $filePath');
      } else {
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to get storage directory');
      }
    } else {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Permission denied');
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
      await AsyncContextHelpers.showSnackBarIfMounted(
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
