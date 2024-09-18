import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

import 'package:webbcheck/src/apps/authed/views/org_selected/org_member_view.dart';
import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/providers/org_member_selector_change_notifier.dart';
import '../../../../shared/providers/firestore_read_service.dart';
import '../../../../shared/widgets.dart';
import '../../../../shared/helpers/async_context_helpers.dart';


class OrgMemberListView extends StatelessWidget {
  OrgMemberListView({super.key});

  static const routeName = '/users';

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Consumer<OrgSelectorChangeNotifier>(
      builder: (context, orgSelectorChangeNotifier, child) {
        return AuthClaimChecker(
          builder: (context, userClaims) {
            return Scaffold(
              appBar: OrgNameAppBar(
                titleSuffix: 'Users',
                actions: [
                  if (userClaims[
                          'org_admin_${orgSelectorChangeNotifier.orgId}'] ==
                      true)
                    ElevatedButton.icon(
                      onPressed: () {
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
                    )
                ],
              ),
              drawer: const AuthedDrawer(),
              body: Consumer<FirestoreReadService>(
                builder: (context, firestoreReadService, child) {
                  return StreamBuilder<List<DocumentSnapshot>>(
                    stream: firestoreReadService.getOrgMembersDocuments(
                        orgSelectorChangeNotifier.orgId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading users'));
                      }
                      final List<DocumentSnapshot> orgMemberDocs =
                          snapshot.data!;

                      return Column(
                        children: [
                          SearchTextField(searchQuery: _searchQuery),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: _searchQuery,
                              builder: (context, query, child) {
                                final lowerCaseQuery = query
                                    .toLowerCase(); // Convert query to lowercase
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
                                              : ' Org Member')
                                          .toString()
                                          .toLowerCase();

                                  return orgMemberEmail
                                          .contains(lowerCaseQuery) ||
                                      orgMemberDisplayName
                                          .contains(lowerCaseQuery) ||
                                      orgMemberRole.contains(lowerCaseQuery);
                                }).toList();

                                return filteredMemberDocs.isNotEmpty
                                    ? SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.95,
                                        child: ListView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: filteredMemberDocs.length,
                                          itemBuilder: (context, index) {
                                            Map<String, dynamic> userData =
                                                filteredMemberDocs[index].data()
                                                    as Map<String, dynamic>;
                                            return UserCard(
                                              userData: userData,
                                            );
                                          },
                                        ),
                                      )
                                    : const Center(
                                        child: Text('No users found'));
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
    _searchController.dispose();
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
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              widget.searchQuery.value = '';
            },
          ),
        ),
        onChanged: (value) {
          widget.searchQuery.value = value;
        },
      ),
    );
  }
}

class AddUserAlertDialog extends StatefulWidget {
  const AddUserAlertDialog({super.key});

  @override
  AddUserAlertDialogState createState() => AddUserAlertDialogState();
}

class AddUserAlertDialogState extends State<AddUserAlertDialog> {
  late TextEditingController _userCreationEmailController;
  var _isLoading = false;

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

  Future<void> _submitEmails(List<String> emails) async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseFunctions.httpsCallable('create_users_callable').call({
        "userEmails": emails,
        "orgId": orgSelectorProvider.orgId,
      });
      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Users from CSV added successfully');
      AsyncContextHelpers.popContextIfMounted(context);
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to add users from CSV: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSubmitSingleEmail() async {
    final userCreationEmail = _userCreationEmailController.text;
    if (userCreationEmail.isNotEmpty) {
      await _submitEmails([userCreationEmail]);
    }
  }


  // Method to parse CSV file
  void _onCsvFileSelected() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String content = '';

      // Handle file content differently for web and mobile
      if (kIsWeb) {
        // Web: Use bytes
        final file = result.files.first;
        content = utf8.decode(file.bytes!);
      } else {
        // Mobile: Use file path
        final path = result.files.single.path;
        if (path != null) {
          final file = io.File(path);
          content = await file.readAsString();
        }
      }

    // Split the CSV content by line breaks
    List<String> lines = content.split(RegExp(r'[\r\n]+'));

    // Skip the first line (header) and process the remaining lines
    if (lines.isNotEmpty) {
      lines = lines.sublist(1);
    }

    // Extract the emails, exclude empty lines
    List<String> emails = lines
        .map((line) => line.trim()) // Trim each line
        .where((line) => line.isNotEmpty) // Exclude empty lines
        .toList();

    // Submit emails if the list is not empty
    if (emails.isNotEmpty) {
      
      await _submitEmails(emails);
    }
    } 
  }



  

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add a new user to this organization'),
              TextField(
                controller: _userCreationEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onSubmitSingleEmail,
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
              onPressed: _isLoading ? null : _onCsvFileSelected,
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
              onPressed: () {
                Navigator.of(context).pop();
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
        ),
      ],
    );
  }
}

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
              Navigator.pushNamed(context, OrgMemberView.routeName);
            });
      },
    );
  }
}
