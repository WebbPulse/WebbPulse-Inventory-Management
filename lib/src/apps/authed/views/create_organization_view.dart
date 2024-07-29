import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/apps/authed/views/org_selection_view.dart';
import 'package:webbcheck/src/shared/helpers/snackbar.dart';

class CreateOrganizationView extends StatelessWidget {
  CreateOrganizationView({
    super.key,
  });
  final TextEditingController _controller = TextEditingController();

  static const routeName = '/create-organization';

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseFunctions>(
        builder: (context, firebaseFunctions, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Organization'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final organizationCreationName = _controller.text;

                  if (organizationCreationName.isNotEmpty) {
                    try {
                      await firebaseFunctions
                          .httpsCallable('create_organization_callable')
                          .call({
                        "organizationCreationName": organizationCreationName,
                      });
                      await AsyncContextHelpers.showSnackBarIfMounted(
                          context, 'Organization created!');
                      Navigator.pushNamed(context, OrgSelectionView.routeName);
                    } catch (e) {
                      await AsyncContextHelpers.showSnackBarIfMounted(
                          context, 'Failed to create organization: $e');
                    }
                  } else {
                    AsyncContextHelpers.showSnackBar(
                        context, 'Please enter an organization name');
                  }
                },
                child: const Text('Create Organization'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
