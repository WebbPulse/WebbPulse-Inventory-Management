import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../shared/providers/firestoreService.dart';
import 'create_organization_view.dart';
import '../../../shared/widgets.dart';
import '../../../shared/providers/orgSelectorChangeNotifier.dart';
import '../../../shared/providers/authenticationChangeNotifier.dart';
import 'checkout_view.dart';

class OrgSelectionView extends StatelessWidget {
  const OrgSelectionView({
    super.key,
  });

  static const routeName = '/select-organization';

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthenticationChangeNotifier, FirestoreService>(
      builder: (context, authProvider, firestoreService, child) =>
          StreamBuilder<List<String>>(
        stream: firestoreService.getUserOrgsIds(authProvider.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('Error loading organizations');
          }
          final List<String> userOrgIds = snapshot.data ?? [];
          return Scaffold(
            appBar: AppBar(title: const Text('Account Selection')),
            body: Column(
              children: [
                const Center(child: Text('Select an Organization')),
                Expanded(
                  child: userOrgIds.isNotEmpty
                      ? CustomLayoutBuilder(
                          childWidget: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: userOrgIds.length + 1,
                            itemBuilder: (context, index) {
                              if (index == userOrgIds.length) {
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
                              final orgId = userOrgIds[index];
                              return OrgCard(
                                orgId: orgId,
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
    required this.orgId,
  });

  final String orgId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<OrgSelectorChangeNotifier, FirestoreService>(
      builder: (context, orgSelectorProvider, firestoreService, child) {
        return StreamBuilder(
          stream: firestoreService.getOrg(orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading organizations');
            }
            final String orgName = snapshot.data?['orgName'] ?? '';

            return CustomCard(
              theme: theme,
              customCardLeading:
                  Icon(Icons.home, color: theme.colorScheme.secondary),
              customCardTitle: Container(
                child: Text(orgName),
              ),
              customCardTrailing: null,
              onTapAction: () {
                orgSelectorProvider.selectOrg(orgId);
                Navigator.pushNamed(context, CheckoutView.routeName);
              },
            );
          },
        );
      },
    );
  }
}
