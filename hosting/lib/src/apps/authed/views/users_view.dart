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

  final TextEditingController _userCreationEmailController =
      TextEditingController();
  static const routeName = '/users';

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgSelectorChangeNotifier, FirestoreService,
        FirebaseFunctions>(
      builder: (context, orgSelectorProvider, firestoreService,
          firebaseFunctions, child) {
        return FutureBuilder<List<DocumentSnapshot>>(
            future: firestoreService
                .getOrgMembers(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<DocumentSnapshot> membersDocs = snapshot.data!;
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Users Page'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Add New User'),
                                content: SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxWidth:
                                            500), // Set your desired width here
                                    child: Column(
                                      mainAxisSize: MainAxisSize
                                          .min, // This ensures the column takes only the necessary space
                                      children: [
                                        const Text(
                                            'Enter the email of the user to add'),
                                        const SizedBox(height: 16.0), // Spacing

                                        TextField(
                                          controller:
                                              _userCreationEmailController,
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
                                      final userCreationEmail =
                                          _userCreationEmailController.text;
                                      if (userCreationEmail.isNotEmpty) {
                                        await firebaseFunctions
                                            .httpsCallable(
                                                'create_user_callable')
                                            .call({
                                          "userCreationEmail":
                                              userCreationEmail,
                                          "orgId":
                                              orgSelectorProvider.selectedOrgId
                                        });
                                        await AsyncContextHelpers
                                            .popContextIfMounted(context);
                                      }
                                    },
                                    child: const Text('Add User'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Add New User'))
                  ],
                ),
                drawer: const AuthedDrawer(),
                body: Column(
                  children: [
                    Padding(
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
                              _searchQuery.value = '';
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _searchQuery.value = value;
                        },
                      ),
                    ),
                    const Center(child: Text('User List')),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (context, query, child) {
                          final filteredMembers = membersDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final email = data['email'] ?? '';
                            final displayName = data['displayName'] ?? '';
                            return email.contains(query) ||
                                displayName.contains(query);
                          }).toList();

                          return filteredMembers.isNotEmpty
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredMembers.length,
                                    itemBuilder: (context, index) {
                                      Map<String, dynamic> userData =
                                          filteredMembers[index].data()
                                              as Map<String, dynamic>;
                                      final orgMemberId =
                                          userData['orgMemberId'];
                                      final displayName =
                                          userData['displayName'];
                                      final email = userData['email'];
                                      return UserCard(
                                        orgMemberId: orgMemberId,
                                        orgId:
                                            orgSelectorProvider.selectedOrgId,
                                        displayName: displayName,
                                        email: email,
                                      );
                                    },
                                  ),
                                )
                              : const Center(child: Text('No users found'));
                        },
                      ),
                    ),
                  ],
                ),
              );
            });
      },
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.orgMemberId,
    required this.orgId,
    required this.displayName,
    required this.email,
  });

  final String orgMemberId;
  final String orgId;
  final String displayName;
  final String email;

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
                  Text(displayName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Wrap(
                children: [
                  Text('Email: ',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(email, style: theme.textTheme.labelSmall),
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
              )
            ]),
            customCardTrailing: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: EdgeInsets.all(5)),
              child: Text('Manage User'),
              onPressed: () {},
            ),
            onTapAction: () {});
      },
    );
  }
}
