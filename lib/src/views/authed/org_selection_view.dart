import 'package:flutter/material.dart';
import 'package:webbcheck/src/views/authed/create_organization_view.dart';
import '../../providers/orgSelectorProvider.dart';
import 'home_view.dart';

class OrgSelectionView extends StatelessWidget {
  OrgSelectionView(
      {super.key,
      required this.organizationUids,
      required this.orgSelectorProvider});

  static const routeName = '/select-organization';

  final List<String> organizationUids;
  final OrgSelectorProvider orgSelectorProvider;

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Scaffold(
      appBar: AppBar(title: Text('Org Selection Page')),
      body: Column(
        children: [
          Center(child: Text('Org Selection Page')),
          for (final orgUid in organizationUids)
            ListTile(
              title: Text(orgUid),
              onTap: () {
                orgSelectorProvider.selectOrg(orgUid);
                Navigator.pop(context);
                Navigator.pushNamed(context, HomeView.routeName);
              },
            ),
          if (organizationUids.isEmpty) Text('No organizations found'),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CreateOrganizationView.routeName);
              },
              child: Text('Create New Organization'))
        ],
      ),
    );
  }
}
