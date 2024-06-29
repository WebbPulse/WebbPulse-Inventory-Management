import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:webbcheck/src/providers/orgSelectorProvider.dart';
import 'package:webbcheck/src/services/firestoreService.dart';
import '../../widgets.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key, required this.firestoreService});

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
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading users');
              }
              final orgMembersUids = snapshot.data ?? [];
              return ScaffoldWithDrawer(
                  title: 'Users',
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
                              return const CircularProgressIndicator();
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
