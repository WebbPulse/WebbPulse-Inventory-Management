import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';

import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';
import 'package:webbcheck/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/widgets/widgets.dart';
import 'package:webbcheck/src/shared/widgets/user_widgets.dart';
import 'package:webbcheck/src/shared/widgets/org_widgets.dart';

/// OrgSettingsView displays the settings page for the selected organization,
/// allowing users to update the organization's name, background image, or delete the organization.
class OrgSettingsView extends StatelessWidget {
  const OrgSettingsView({super.key});
  static const routeName = '/org-settings';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the theme data for styling

    return OrgDocumentStreamBuilder(builder: (context, orgDocument) {
      return Scaffold(
        appBar: const OrgNameAppBar(
          titleSuffix:
              'Settings', // App bar shows the organization's name and "Settings"
        ),
        drawer: const AuthedDrawer(), // Sidebar drawer for navigation
        body: Stack(
          children: [
            // Display organization background image if available
            if (orgDocument['orgBackgroundImageURL'] != null &&
                orgDocument['orgBackgroundImageURL'] != '')
              Positioned.fill(
                child: Image.network(
                  orgDocument[
                      'orgBackgroundImageURL'], // Display background image from URL
                  fit: BoxFit.cover, // Fit the image to cover the background
                ),
              ),
            SafeArea(
              child: SizedBox.expand(
                child: Consumer4<
                    OrgSelectorChangeNotifier,
                    FirestoreReadService,
                    AuthenticationChangeNotifier,
                    FirebaseFunctions>(
                  builder: (context, orgSelectorProvider, firestoreService,
                      authenticationChangeNotifier, firebaseFunctions, child) {
                    return SingleChildScrollView(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Set maximum width for the card based on screen size
                            double maxWidth;
                            if (constraints.maxWidth < 600) {
                              maxWidth = constraints.maxWidth * 0.95;
                            } else if (constraints.maxWidth < 1200) {
                              maxWidth = constraints.maxWidth * 0.6;
                            } else {
                              maxWidth = constraints.maxWidth * 0.4;
                            }

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxWidth, // Limit the card's width
                              ),
                              child: Card(
                                elevation:
                                    4.0, // Card elevation for shadow effect
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      16.0), // Padding around the content
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Organization Settings', // Title of the settings page
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      // Widget to edit the organization name
                                      OrgNameEditor(
                                        orgDocument: orgDocument,
                                      ),
                                      const SizedBox(height: 16),
                                      // Button to change the organization image
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return OrgImageEditorAlertDialog(
                                                  orgDocument: orgDocument,
                                                );
                                              });
                                        },
                                        icon: const Icon(Icons.image),
                                        label: const Text(
                                            'Change Organization Image'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme
                                              .colorScheme.surface
                                              .withOpacity(0.95),
                                          side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.all(16.0),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Button to delete the organization with red background
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return DeleteOrgAlertDialog(
                                                  orgDocument: orgDocument,
                                                );
                                              });
                                        },
                                        icon: const Icon(Icons.delete),
                                        label:
                                            const Text('Delete Organization'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.all(16.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// OrgNameEditor provides a text field to edit the organization's name.
class OrgNameEditor extends StatefulWidget {
  final dynamic orgDocument;

  const OrgNameEditor({super.key, required this.orgDocument});

  @override
  _OrgNameEditorState createState() => _OrgNameEditorState();
}

class _OrgNameEditorState extends State<OrgNameEditor> {
  late TextEditingController orgNameController; // Controller for the text field
  var _isLoading = false; // Tracks the loading state during submission

  @override
  void initState() {
    super.initState();
    orgNameController = TextEditingController(
        text: widget.orgDocument['orgName']
            as String); // Initialize controller with the current org name
  }

  @override
  void dispose() {
    orgNameController.dispose(); // Dispose the controller when done
    super.dispose();
  }

  /// Handles the submission of the new organization name.
  void _onSubmit() async {
    final newName = orgNameController.text; // Get the new name from the input
    final firebaseFunctions = Provider.of<FirebaseFunctions>(context,
        listen: false); // Access Firebase Functions

    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      await firebaseFunctions.httpsCallable('update_org_name_callable').call({
        'orgId': widget.orgDocument.id,
        'orgName': newName,
      });

      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Org name changed successfully'); // Show success message
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to change Org name: $e'); // Show error message
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: orgNameController, // Bind controller to text field
      decoration: InputDecoration(
        labelText: 'Organization Name', // Label for the text field
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.edit), // Prefix icon for the text field
        suffixIcon: IconButton(
          icon: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator if waiting
              : const Icon(Icons.check), // Check icon for submission
          onPressed:
              _isLoading ? null : _onSubmit, // Disable button while loading
        ),
      ),
    );
  }
}

/// OrgImageEditorAlertDialog allows users to change the organization's background image URL.
class OrgImageEditorAlertDialog extends StatefulWidget {
  final dynamic orgDocument;

  const OrgImageEditorAlertDialog({super.key, required this.orgDocument});

  @override
  OrgImageEditorAlertDialogState createState() =>
      OrgImageEditorAlertDialogState();
}

class OrgImageEditorAlertDialogState extends State<OrgImageEditorAlertDialog> {
  late TextEditingController
      urlController; // Controller for the image URL input
  var _isLoading = false; // Tracks loading state

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(); // Initialize the controller
  }

  @override
  void dispose() {
    urlController.dispose(); // Dispose controller when done
    super.dispose();
  }

  /// Handles the submission of the new background image URL.
  void _onSubmit() async {
    final newOrgImageUrl = urlController.text; // Get the new image URL
    final firebaseFunctions = Provider.of<FirebaseFunctions>(context,
        listen: false); // Access Firebase Functions

    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      await firebaseFunctions
          .httpsCallable('update_org_background_image_callable')
          .call({
        'orgId': widget.orgDocument.id,
        'orgBackgroundImageURL': newOrgImageUrl,
      });

      AsyncContextHelpers.showSnackBarIfMounted(context,
          'Org background image changed successfully'); // Show success message
      AsyncContextHelpers.popContextIfMounted(context); // Close the dialog
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(context,
          'Failed to change Org background image: $e'); // Show error message
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the theme
    return AlertDialog(
      title: const Text('Change Organization Image URL'), // Dialog title
      content: SizedBox(
        height: 120,
        child: Column(
          children: [
            const Text(
              'Please enter the URL of the new image for the organization background:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController, // TextField for the image URL
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          onPressed:
              _isLoading ? null : _onSubmit, // Disable button while loading
          icon: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator while waiting
              : const Icon(Icons.photo),
          label: const Text('Change Organization Image'), // Button label
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
        ),
      ],
    );
  }
}

/// DeleteOrgAlertDialog confirms and handles the deletion of the organization.
class DeleteOrgAlertDialog extends StatefulWidget {
  final dynamic orgDocument;

  const DeleteOrgAlertDialog({super.key, required this.orgDocument});

  @override
  DeleteOrgAlertDialogState createState() => DeleteOrgAlertDialogState();
}

class DeleteOrgAlertDialogState extends State<DeleteOrgAlertDialog> {
  var _isLoading = false; // Tracks the loading state during deletion

  /// Handles the deletion of the organization.
  void _onSubmit() async {
    final firebaseFunctions = Provider.of<FirebaseFunctions>(context,
        listen: false); // Access Firebase Functions
    final authenticationChangeNotifier =
        Provider.of<AuthenticationChangeNotifier>(context,
            listen: false); // Access authentication change notifier

    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      await firebaseFunctions.httpsCallable('delete_org_callable').call({
        'orgId': widget
            .orgDocument.id, // Pass the organization ID to the cloud function
      });
      authenticationChangeNotifier
          .signOutUser(); // Sign out the user after deleting the organization
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to delete Org: $e'); // Show error message
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the theme
    return AlertDialog(
      title: const Text('Delete Organization'), // Dialog title
      content: const Text(
          'Are you sure you want to delete this organization? This action cannot be undone.'), // Confirmation message
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed:
              _isLoading ? null : _onSubmit, // Disable button while loading
          icon: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator while waiting
              : const Icon(Icons.delete), // Delete icon for the button
          label: const Text('Delete Organization'), // Button label
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red background to indicate danger
            padding: const EdgeInsets.all(16.0),
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
        ),
      ],
    );
  }
}
