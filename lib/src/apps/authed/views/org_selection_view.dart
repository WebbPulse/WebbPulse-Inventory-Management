import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:webbcheck/src/shared/services/firestoreService.dart';
import 'package:webbcheck/src/apps/authed/views/create_organization_view.dart';
import 'package:webbcheck/src/shared/widgets.dart';
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
                      ? CustomLayoutBuilder(
                          childWidget: ListView.builder(
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
  });

  final String orgUid;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

            return CustomCard(
              theme: theme,
              customCardLeading:
                  Icon(Icons.home, color: theme.colorScheme.secondary),
              titleText: orgName,
              customCardTrailing: null,
              onTapAction: () {
                orgSelectorProvider.selectOrg(orgUid);
                Navigator.pushNamed(context, CheckoutView.routeName);
              },
            );
          },
        );
      },
    );
  }
}
