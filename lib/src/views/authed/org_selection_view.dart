import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:webbcheck/src/services/firestoreService.dart';
import 'package:webbcheck/src/views/authed/create_organization_view.dart';
import '../../providers/orgSelectorProvider.dart';
import 'home_view.dart';

class OrgSelectionView extends StatelessWidget {
  const OrgSelectionView({
    super.key,
    required this.organizationUids,
    required this.firestoreService,
  });

  static const routeName = '/select-organization';

  final List<String> organizationUids;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) => Scaffold(
        appBar: AppBar(title: const Text('Org Selection Page')),
        body: Column(
          children: [
            const Center(child: Text('Org Selection Page')),
            for (final orgUid in organizationUids)
              StreamBuilder(
                stream: firestoreService.getOrgNameStream(orgUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error loading organizations');
                  }
                  final String orgName = snapshot.data ?? '';

                  return ListTile(
                    title: Text(orgName),
                    onTap: () {
                      orgSelectorProvider.selectOrg(orgUid);
                      Navigator.pop(context);
                      Navigator.pushNamed(context, HomeView.routeName);
                    },
                  );
                },
              ),
            if (organizationUids.isEmpty) const Text('No organizations found'),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                      context, CreateOrganizationView.routeName);
                },
                child: const Text('Create New Organization'))
          ],
        ),
      ),
    );
  }
}
