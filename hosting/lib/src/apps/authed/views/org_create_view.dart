import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';

import 'org_selection_view.dart';
import '../../../shared/widgets/widgets.dart';

class OrgCreateView extends StatelessWidget {
  const OrgCreateView({super.key});

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
  CreateOrganizationFormState createState() => CreateOrganizationFormState();
}

class CreateOrganizationFormState extends State<CreateOrganizationForm> {
  late TextEditingController _controller;
  var _isLoading = false;

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

  void _onSubmit() async {
    final orgName = _controller.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    final firebaseAuth =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false);

    if (orgName.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        await firebaseFunctions
            .httpsCallable('create_organization_callable')
            .call({
          "orgName": orgName,
        });

        /// Refresh the user's ID token to get the roles for the newly created organization
        await firebaseAuth.user!.getIdToken(true);

        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Organization created!');
        Navigator.pushNamed(context, OrgSelectionView.routeName);
      } catch (e) {
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to create organization: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      AsyncContextHelpers.showSnackBar(
          context, 'Please enter an organization name');
    }
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
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.add),
          label: const Text('Create Organization'),
        ),
      ],
    );
  }
}
