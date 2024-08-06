import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'org_selection_view.dart';
import '../../../shared/helpers/asyncContextHelpers.dart';

class CreateOrganizationView extends StatelessWidget {
  CreateOrganizationView({super.key});

  static const routeName = '/create-organization';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Organization'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: CreateOrganizationForm(),
      ),
    );
  }
}

class CreateOrganizationForm extends StatefulWidget {
  const CreateOrganizationForm({super.key});

  @override
  _CreateOrganizationFormState createState() => _CreateOrganizationFormState();
}

class _CreateOrganizationFormState extends State<CreateOrganizationForm> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            final orgName = _controller.text;
            final firebaseFunctions =
                Provider.of<FirebaseFunctions>(context, listen: false);

            if (orgName.isNotEmpty) {
              try {
                await firebaseFunctions
                    .httpsCallable('create_organization_callable')
                    .call({
                  "orgName": orgName,
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
    );
  }
}
