import 'package:cloud_functions/cloud_functions.dart';
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

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Consumer3<OrgSelectorChangeNotifier, FirestoreService,
        FirebaseFunctions>(
      builder: (context, orgSelectorProvider, firestoreService,
          firebaseFunctions, child) {
        return StreamBuilder<List<String>>(
            stream: firestoreService
                .getOrgMembersUidsStream(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Text('Error loading users');
              }
              final orgMembersIds = snapshot.data ?? [];
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
                                          const SizedBox(
                                              height: 16.0), // Spacing

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
                                            "orgId": orgSelectorProvider
                                                .selectedOrgId
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
                      const Center(child: Text('Users Page')),
                      for (final orgMembersId in orgMembersIds)
                        StreamBuilder(
                          stream: firestoreService.getMemberDisplayNameStream(
                              orgMembersId, orgSelectorProvider.selectedOrgId),
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
                      if (orgMembersIds.isEmpty) const Text('No users found'),
                    ],
                  ));
            });
      },
    );
  }
}
