import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/views/authed/org_selection_view.dart';
import 'package:webbcheck/src/providers/authenticationProvider.dart';

import '../../services/firestoreService.dart';

class CreateOrganizationView extends StatelessWidget {
  CreateOrganizationView({super.key, required this.firestoreService});

  static const routeName = '/create-organization';

  final TextEditingController _controller = TextEditingController();
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
        builder: (context, authProvider, child) {
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
                      await firestoreService.createOrganization(
                          organizationCreationName,
                          authProvider.uid,
                          authProvider.displayName,
                          authProvider.email);
                      while (context.mounted == false) {
                        await Future.delayed(const Duration(milliseconds: 100));
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Organization created successfully!'),
                        ));
                        Navigator.pop(context);
                        Navigator.pushNamed(
                            context, OrgSelectionView.routeName);
                      }
                    } catch (e) {
                      while (context.mounted == false) {
                        await Future.delayed(const Duration(milliseconds: 100));
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed to create organization: $e'),
                        ));
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter an organization name'),
                    ));
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
