import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/orgMemberSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/providers/orgSelectorChangeNotifier.dart';

import '../../../shared/widgets.dart';

class ManageUserView extends StatelessWidget {
  const ManageUserView({super.key});
  static const routeName = '/manage-user';

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrgSelectorChangeNotifier,
            OrgMemberSelectorChangeNotifier>(
        builder:
            (context, orgSelectorProvider, orgMemberSelectorProvider, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage User'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              /// Clear the selected org member
              orgMemberSelectorProvider.clearSelectedOrgMember();
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(orgSelectorProvider.selectedOrgId),
              Text(orgMemberSelectorProvider.selectedOrgMemberId),
            ],
          ),
        ),
      );
    });
  }
}
