import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/orgSelectorChangeNotifier.dart';
import '../../../shared/providers/firestoreService.dart';
import '../../../shared/widgets.dart';
import '../../../shared/helpers/asyncContextHelpers.dart';

class UsersView extends StatelessWidget {
  UsersView({super.key});

  static const routeName = '/users';

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Page'),
        actions: [
          AddUserButton(),
        ],
      ),
      drawer: const AuthedDrawer(),
      body: Consumer2<OrgSelectorChangeNotifier, FirestoreService>(
        builder: (context, orgSelectorProvider, firestoreService, child) {
          return FutureBuilder<List<DocumentSnapshot>>(
            future: firestoreService
                .getOrgMembers(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
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
                        final filteredMemberDocs = orgMemberDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final orgMemberEmail = data['orgMemberEmail'] ?? '';
                          final orgMemberDisplayName =
                              data['orgMemberDisplayName'] ?? '';
                          return orgMemberEmail.contains(query) ||
                              orgMemberDisplayName.contains(query);
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
                                    final orgMemberId = userData['orgMemberId'];
                                    final orgMemberDisplayName =
                                        userData['orgMemberDisplayName'];
                                    final email = userData['orgMemberEmail'];
                                    return UserCard(
                                      orgMemberId: orgMemberId,
                                      orgId: orgSelectorProvider.selectedOrgId,
                                      orgMemberDisplayName:
                                          orgMemberDisplayName,
                                      orgMemberEmail: email,
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

  SearchTextField({required this.searchQuery});

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
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
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
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

class AddUserButton extends StatefulWidget {
  @override
  _AddUserButtonState createState() => _AddUserButtonState();
}

class _AddUserButtonState extends State<AddUserButton> {
  final TextEditingController _userCreationEmailController =
      TextEditingController();

  @override
  void dispose() {
    _userCreationEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
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
                ElevatedButton(
                  onPressed: () async {
                    final userCreationEmail = _userCreationEmailController.text;
                    final orgSelectorProvider =
                        Provider.of<OrgSelectorChangeNotifier>(context,
                            listen: false);
                    final firebaseFunctions =
                        Provider.of<FirebaseFunctions>(context, listen: false);
                    if (userCreationEmail.isNotEmpty) {
                      try {
                        await firebaseFunctions
                            .httpsCallable('create_user_callable')
                            .call({
                          "userEmail": userCreationEmail,
                          "orgId": orgSelectorProvider.selectedOrgId,
                        });
                        await AsyncContextHelpers.popContextIfMounted(context);
                      } catch (e) {
                        await AsyncContextHelpers.showSnackBarIfMounted(
                            context, 'Failed to create organization: $e');
                      }
                    }
                  },
                  child: const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
      child: const Text('Add New User'),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.orgMemberId,
    required this.orgId,
    required this.orgMemberDisplayName,
    required this.orgMemberEmail,
  });

  final String orgMemberId;
  final String orgId;
  final String orgMemberDisplayName;
  final String orgMemberEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<FirestoreService>(
      builder: (context, firestoreService, child) {
        return CustomCard(
            theme: theme,
            customCardLeading:
                Icon(Icons.person, color: theme.colorScheme.secondary),
            customCardTitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                children: [
                  Text(orgMemberDisplayName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Roles: ',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('no role logic implemented yet',
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ]),
            customCardTrailing: ElevatedButton(
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
              child: Text('Manage User'),
              onPressed: () {},
            ),
            onTapAction: () {});
      },
    );
  }
}
