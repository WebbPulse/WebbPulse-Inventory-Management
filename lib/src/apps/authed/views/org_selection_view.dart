import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/services/firestoreService.dart';
import 'package:webbcheck/src/apps/authed/views/create_organization_view.dart';
import '../../../shared/providers/orgSelectorProvider.dart';
import '../../../shared/providers/authenticationProvider.dart';
import 'checkout_view.dart';

class OrgSelectionView extends StatelessWidget {
  const OrgSelectionView({
    super.key,
    required this.firestoreService,
  });

  static const routeName = '/select-organization';

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    final theme = Theme.of(context);
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) => StreamBuilder<List<String>>(
        stream: firestoreService.orgsUidsStream(authProvider.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('Error loading organizations');
          }
          final List<String> organizationUids = snapshot.data ?? [];
          return Scaffold(
            appBar: AppBar(title: const Text('Account Selection')),
            body: Column(
              children: [
                const Center(child: Text('Select an Organization')),
                Expanded(
                  child: organizationUids.isNotEmpty
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: organizationUids.length + 1,
                            itemBuilder: (context, index) {
                              if (index == organizationUids.length) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context,
                                          CreateOrganizationView.routeName);
                                    },
                                    child:
                                        const Text('Create New Organization'),
                                  ),
                                );
                              }
                              final orgUid = organizationUids[index];
                              return OrgCard(
                                orgUid: orgUid,
                                firestoreService: firestoreService,
                                theme: theme,
                              );
                            },
                          ),
                        )
                      : Column(
                          children: [
                            const Text('No organizations found'),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, CreateOrganizationView.routeName);
                              },
                              child: const Text('Create New Organization'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrgCard extends StatelessWidget {
  const OrgCard({
    super.key,
    required this.orgUid,
    required this.firestoreService,
    required this.theme,
  });

  final String orgUid;
  final FirestoreService firestoreService;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) {
        return StreamBuilder(
          stream: firestoreService.getOrgNameStream(orgUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading organizations');
            }
            final String orgName = snapshot.data ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                tileColor: theme.colorScheme.secondary.withOpacity(0.1),
                leading: Icon(Icons.home, color: theme.colorScheme.secondary),
                title: Text(
                  orgName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary),
                ),
                onTap: () {
                  orgSelectorProvider.selectOrg(orgUid);
                  Navigator.pushNamed(context, CheckoutView.routeName);
                },
              ),
            );
          },
        );
      },
    );
  }
}
