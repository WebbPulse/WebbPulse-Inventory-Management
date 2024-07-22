import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:webbcheck/src/shared/providers/orgSelectorProvider.dart';
import 'package:webbcheck/src/shared/services/firestoreService.dart';
import 'package:webbcheck/src/shared/services/authService.dart';
import '../../../shared/widgets.dart';

class UsersView extends StatelessWidget {
  UsersView({super.key, required this.firestoreService});

  final AuthService authService = AuthService();
  final TextEditingController _controller = TextEditingController();
  final FirestoreService firestoreService;
  static const routeName = '/users';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) {
        return StreamBuilder<List<String>>(
            stream: firestoreService
                .getOrgMembersUidsStream(orgSelectorProvider.selectedOrgUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Text('Error loading users');
              }
              final orgMembersUids = snapshot.data ?? [];
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
                                  title: Text('Add New User'),
                                  content: SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth:
                                              500), // Set your desired width here
                                      child: Column(
                                        mainAxisSize: MainAxisSize
                                            .min, // This ensures the column takes only the necessary space
                                        children: [
                                          Text(
                                              'Enter the email of the user to add'),
                                          SizedBox(height: 16.0), // Spacing
                                          TextField(
                                            controller: _controller,
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
                                            _controller.text;
                                        if (userCreationEmail.isNotEmpty) {
                                          print('User created');
                                          Navigator.of(context).pop();
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
                  drawer: AuthedDrawer(),
                  body: Column(
                    children: [
                      const Center(child: Text('Users Page')),
                      for (final orgMembersUid in orgMembersUids)
                        StreamBuilder(
                          stream: firestoreService.getMemberDisplayNameStream(
                              orgMembersUid,
                              orgSelectorProvider.selectedOrgUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Text('Error loading users');
                            }
                            final memberUsername = snapshot.data ?? '';

                            return ListTile(
                              title: Text(memberUsername),
                              onTap: () {},
                            );
                          },
                        ),
                      if (orgMembersUids.isEmpty) const Text('No users found'),
                    ],
                  ));
            });
      },
    );
  }
}