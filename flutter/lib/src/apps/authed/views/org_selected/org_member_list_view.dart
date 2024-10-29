import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html; // Universal web support

import 'package:webbpulse_inventory_management/src/apps/authed/views/org_selected/org_member_view.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_member_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/org_widgets.dart';

/// OrgMemberListView displays a list of members in the selected organization.
/// It also includes functionality for searching, adding, and managing users.
class OrgMemberListView extends StatelessWidget {
  OrgMemberListView({super.key});

  static const routeName = '/users'; // Route name for navigation
  final ValueNotifier<String> _searchQuery =
      ValueNotifier<String>(''); // Search query state

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Getting the current theme
    return Consumer<OrgSelectorChangeNotifier>(
      builder: (context, orgSelectorChangeNotifier, child) {
        return AuthClaimChecker(
          builder: (context, userClaims) {
            return Scaffold(
              appBar: OrgNameAppBar(
                titleSuffix: 'Users',
                actions: [
                  // Display the "Add New User" button only if the user is an organization admin
                  if (userClaims[
                          'org_admin_${orgSelectorChangeNotifier.orgId}'] ==
                      true)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show dialog to add a new user
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AddUserAlertDialog();
                          },
                        );
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
                      label: const Text('Add New User'),
                      icon: const Icon(Icons.person_add),
                    ),
                ],
              ),
              drawer: const AuthedDrawer(), // Drawer for navigation
              body: Consumer<FirestoreReadService>(
                builder: (context, firestoreReadService, child) {
                  // StreamBuilder to get the list of organization members from Firestore
                  return StreamBuilder<List<DocumentSnapshot>>(
                    stream: firestoreReadService.getOrgMembersDocuments(
                        orgSelectorChangeNotifier.orgId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator()); // Show loading indicator
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text(
                                'Error loading users')); // Show error if failed to load
                      }

                      final List<DocumentSnapshot> orgMemberDocs =
                          snapshot.data!; // Retrieve the documents

                      return Column(
                        children: [
                          // Search field for filtering users
                          SearchTextField(searchQuery: _searchQuery),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: _searchQuery,
                              builder: (context, query, child) {
                                final lowerCaseQuery = query
                                    .toLowerCase(); // Convert search query to lowercase

                                // Filter the user documents based on the search query
                                final filteredMemberDocs =
                                    orgMemberDocs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final orgMemberEmail =
                                      (data['orgMemberEmail'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final orgMemberDisplayName =
                                      (data['orgMemberDisplayName'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final orgMemberRole =
                                      (data['orgMemberRole'] == 'admin'
                                              ? 'Org Admin'
                                              : 'Org Member')
                                          .toLowerCase();

                                  return orgMemberEmail
                                          .contains(lowerCaseQuery) ||
                                      orgMemberDisplayName
                                          .contains(lowerCaseQuery) ||
                                      orgMemberRole.contains(lowerCaseQuery);
                                }).toList();

                                // Display filtered list of users or a message if no users are found
                                return filteredMemberDocs.isNotEmpty
                                    ? LayoutBuilder(
                                        builder: (context, constraints) {
                                        return SizedBox(
                                          width: constraints.maxWidth * 0.95,
                                          child: ListView.builder(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                filteredMemberDocs.length,
                                            itemBuilder: (context, index) {
                                              Map<String, dynamic> userData =
                                                  filteredMemberDocs[index]
                                                          .data()
                                                      as Map<String, dynamic>;
                                              return UserCard(
                                                  userData:
                                                      userData); // Display each user in a card
                                            },
                                          ),
                                        );
                                      })
                                    : const Center(
                                        child: Text(
                                            'No users found')); // Show message if no users match
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// SearchTextField provides a search input field for filtering users in the list.
class SearchTextField extends StatefulWidget {
  final ValueNotifier<String> searchQuery;

  const SearchTextField({super.key, required this.searchQuery});

  @override
  SearchTextFieldState createState() => SearchTextFieldState();
}

class SearchTextFieldState extends State<SearchTextField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController
        .dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search by Email or Display Name',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear), // Clear button for the search field
            onPressed: () {
              _searchController.clear(); // Clear the search field
              widget.searchQuery.value = ''; // Reset the search query
            },
          ),
        ),
        onChanged: (value) {
          widget.searchQuery.value =
              value; // Update search query as the user types
        },
      ),
    );
  }
}

/// AddUserAlertDialog allows admins to add users to the organization either by entering individual emails or uploading a CSV file.
class AddUserAlertDialog extends StatefulWidget {
  const AddUserAlertDialog({super.key});

  @override
  AddUserAlertDialogState createState() => AddUserAlertDialogState();
}

class AddUserAlertDialogState extends State<AddUserAlertDialog> {
  late TextEditingController _userCreationEmailController;
  var _isLoading = false; // State to show loading indicator while processing
  final String csvTemplate =
      "Email\njohndoe@example.com\njanedoe@example.com"; // CSV template for adding users

  @override
  void initState() {
    super.initState();
    _userCreationEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _userCreationEmailController.dispose();
    super.dispose();
  }

  // Method to handle both Web and Mobile/Other platforms for downloading CSV templates
  Future<void> downloadCSV() async {
    if (kIsWeb) {
      downloadCSVForWeb(); // Trigger CSV download for Web
    } else {
      await downloadCSVForMobile(); // Save CSV to file for Mobile/Desktop
    }
  }

  // Download CSV file for Web using HTML anchor element
  void downloadCSVForWeb() {
    final bytes = utf8.encode(csvTemplate); // Convert CSV template to bytes
    final blob = html.Blob([bytes], 'text/csv'); // Create a Blob for CSV data

    // Create and trigger the download
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "user_template.csv") // Specify file name
      ..click(); // Trigger the download
    html.Url.revokeObjectUrl(url); // Clean up memory
  }

  // Download CSV file for Mobile/Desktop platforms
  Future<void> downloadCSVForMobile() async {
    var status =
        await Permission.storage.request(); // Request storage permissions
    if (status.isGranted) {
      final directory =
          await getExternalStorageDirectory(); // Get the directory to save the file
      if (directory != null) {
        String filePath =
            '${directory.path}/user_template.csv'; // Define file path

        io.File file = io.File(filePath); // Create the file
        await file.writeAsString(csvTemplate); // Write the CSV content

        // Show message that the file has been saved
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'CSV Template saved to $filePath');
      } else {
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to get storage directory');
      }
    } else {
      await AsyncContextHelpers.showSnackBarIfMounted(context, 'Permission denied');
    }
  }

  // Submits a list of emails to create users in the organization
  Future<void> _submitEmails(List<String> emails) async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true; // Show loading indicator while submitting
    });

    try {
      await firebaseFunctions.httpsCallable('create_users_callable').call({
        "userEmails": emails,
        "orgId": orgSelectorProvider.orgId, // Pass organization ID and emails
      });
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Users added successfully');
      AsyncContextHelpers.popContextIfMounted(
          context); // Close the dialog after submission
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to add users: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  // Submits a single email
  void _onSubmitSingleEmail() async {
    final userCreationEmail = _userCreationEmailController.text;
    if (userCreationEmail.isNotEmpty) {
      await _submitEmails([userCreationEmail]); // Submit the single email
    }
  }

  // Method to handle CSV file selection and parsing
  void _onCsvFileSelected() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'], // Allow only CSV files
    );

    if (result != null) {
      String content = '';

      // Handle file content differently for Web and Mobile/Desktop
      if (kIsWeb) {
        final file = result.files.first;
        content = utf8.decode(file.bytes!); // Decode file bytes on web
      } else {
        final path = result.files.single.path;
        if (path != null) {
          final file = io.File(path);
          content = await file.readAsString(); // Read file content on mobile
        }
      }

      List<String> lines =
          content.split(RegExp(r'[\r\n]+')); // Split CSV content into lines

      if (lines.isNotEmpty) {
        lines = lines.sublist(1); // Skip the header line
      }

      List<String> emails = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(); // Extract emails

      if (emails.isNotEmpty) {
        await _submitEmails(emails); // Submit emails from CSV
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Get the current theme
    return AlertDialog(
      title: const Text('Add New User'), // Title of the dialog
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 500), // Set max width for dialog
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add a new user to this organization'),
              TextField(
                controller: _userCreationEmailController,
                decoration: const InputDecoration(
                    labelText: 'Email'), // Input for a single email
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed:
              _isLoading ? null : _onSubmitSingleEmail, // Submit single email
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
              : const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : _onCsvFileSelected, // Submit multiple users via CSV
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
              : const Icon(Icons.upload_file),
          label: const Text('Add Users from CSV'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () async {
            await downloadCSV(); // Download CSV template
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Download CSV Template'),
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
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
        ),
      ],
    );
  }
}

/// UserCard is a widget that displays user details such as display name, email, and role in the organization.
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.userData,
  });

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<FirestoreReadService, OrgMemberSelectorChangeNotifier>(
      builder:
          (context, firestoreService, orgMemberSelectorChangeNotifier, child) {
        String orgMemberDisplayName =
            userData['orgMemberDisplayName'] ?? 'Display Name Loading...';
        String orgMemberEmail =
            userData['orgMemberEmail'] ?? 'Email Loading...';
        String orgMemberRole = userData['orgMemberRole'] ?? 'Role Loading...';
        bool orgMemberDeleted = userData['orgMemberDeleted'] ?? false;

        // Hide the card if the user is marked as deleted
        if (orgMemberDeleted) {
          return const SizedBox.shrink();
        }

        return CustomCard(
          theme: theme,
          customCardLeading:
              Icon(Icons.person, color: theme.colorScheme.secondary),
          customCardTitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              children: [
                Text(orgMemberDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Wrap(
              children: [
                Text('Email: ',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(orgMemberEmail, style: theme.textTheme.labelSmall),
              ],
            ),
            Wrap(
              children: [
                Text('Role: ',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(orgMemberRole == 'admin' ? 'Org Admin' : 'Org Member',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ]),
          customCardTrailing: null,
          onTapAction: () {
            orgMemberSelectorChangeNotifier
                .selectOrgMember(userData['orgMemberId']);
            Navigator.pushNamed(context,
                OrgMemberView.routeName); // Navigate to user details view
          },
        );
      },
    );
  }
}
