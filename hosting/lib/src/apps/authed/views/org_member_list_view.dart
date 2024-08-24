import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/apps/authed/views/org_member_view.dart';

import '../../../shared/providers/org_selector_change_notifier.dart';
import '../../../shared/providers/org_member_selector_change_notifier.dart';
import '../../../shared/providers/firestore_read_service.dart';
import '../../../shared/widgets.dart';
import '../../../shared/helpers/async_context_helpers.dart';

class OrgMemberListView extends StatelessWidget {
  OrgMemberListView({super.key});

  static const routeName = '/users';

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Page'),
        actions: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AddUserAlertDialog();
                },
              );
            },
            style:
                ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
            child: const Text('Add New User'),
          )
        ],
      ),
      drawer: const AuthedDrawer(),
      body: Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(
        builder: (context, orgSelectorProvider, firestoreService, child) {
          return StreamBuilder<List<DocumentSnapshot>>(
            stream: firestoreService
                .getOrgMembersDocuments(orgSelectorProvider.orgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading users'));
              }
              final List<DocumentSnapshot> orgMemberDocs = snapshot.data!;

              return Column(
                children: [
                  SearchTextField(searchQuery: _searchQuery),
                  const Center(child: Text('User List')),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, child) {
                        final lowerCaseQuery =
                            query.toLowerCase(); // Convert query to lowercase
                        final filteredMemberDocs = orgMemberDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final orgMemberEmail = (data['orgMemberEmail'] ?? '')
                              .toString()
                              .toLowerCase();
                          final orgMemberDisplayName =
                              (data['orgMemberDisplayName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                          final orgMemberRole = (data['orgMemberRole'] ?? '')
                              .toString()
                              .toLowerCase();

                          return orgMemberEmail.contains(lowerCaseQuery) ||
                              orgMemberDisplayName.contains(lowerCaseQuery) ||
                              orgMemberRole.contains(lowerCaseQuery);
                        }).toList();

                        return filteredMemberDocs.isNotEmpty
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width * 0.95,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
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
                            : const Center(child: Text('No users found'));
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

  void _onSubmit() async {
    final userCreationEmail = _userCreationEmailController.text;
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    if (userCreationEmail.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await firebaseFunctions.httpsCallable('create_user_callable').call({
          "userEmail": userCreationEmail,
          "orgId": orgSelectorProvider.orgId,
        });
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'User created successfully');
        AsyncContextHelpers.popContextIfMounted(context);
      } catch (e) {
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to create user: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the email of the user to add'),
              const SizedBox(height: 16.0),
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
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.add),
          label: const Text('Add User'),
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
                  Text(orgMemberRole, style: theme.textTheme.labelSmall),
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
