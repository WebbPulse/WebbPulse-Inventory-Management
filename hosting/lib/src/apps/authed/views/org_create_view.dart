import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';

import 'org_selection_view.dart';
import 'package:webbcheck/src/shared/widgets/widgets.dart';

/// OrgCreateView provides the UI for creating a new organization.
/// Users can enter a name for their organization and submit the form to create it.
class OrgCreateView extends StatelessWidget {
  const OrgCreateView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/create-organization';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Organization'), // Title for the AppBar
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0), // Padding around the form
        child:
            CreateOrganizationForm(), // The form widget for creating an organization
      ),
    );
  }
}

/// Stateful widget that holds the form for creating a new organization.
class CreateOrganizationForm extends StatefulWidget {
  const CreateOrganizationForm({super.key});

  @override
  CreateOrganizationFormState createState() => CreateOrganizationFormState();
}

class CreateOrganizationFormState extends State<CreateOrganizationForm> {
  late TextEditingController
      _controller; // Controller for the organization name input
  var _isLoading = false; // Tracks the loading state during form submission

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(); // Initialize the text controller
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  /// Handles the submission of the organization creation form.
  void _onSubmit() async {
    final orgName =
        _controller.text; // Get the organization name from the input
    final firebaseFunctions = Provider.of<FirebaseFunctions>(context,
        listen: false); // Access Firebase Functions
    final firebaseAuth = Provider.of<AuthenticationChangeNotifier>(context,
        listen: false); // Access Firebase Auth

    if (orgName.isNotEmpty) {
      try {
        setState(() => _isLoading = true); // Set loading state to true
        await firebaseFunctions
            .httpsCallable(
                'create_organization_callable') // Call the cloud function to create the organization
            .call({
          "orgName": orgName, // Pass the organization name
        });

        /// Refresh the user's ID token to get the roles for the newly created organization
        await firebaseAuth.user!.getIdToken(true);

        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Organization created!'); // Show success message
        Navigator.pushNamed(
            context,
            OrgSelectionView
                .routeName); // Navigate back to the organization selection view
      } catch (e) {
        AsyncContextHelpers.showSnackBarIfMounted(context,
            'Failed to create organization: $e'); // Show error message on failure
      } finally {
        setState(() => _isLoading = false); // Reset loading state
      }
    } else {
      AsyncContextHelpers.showSnackBar(context,
          'Please enter an organization name'); // Show message if organization name is empty
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TextField for entering the organization name
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Organization Name', // Label for the input field
          ),
        ),
        const SizedBox(height: 16.0), // Add spacing between input and button
        // Button for submitting the form
        ElevatedButton.icon(
          onPressed:
              _isLoading ? null : _onSubmit, // Disable button when loading
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
          icon: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator if waiting for the response
              : const Icon(Icons.add), // Show add icon when not loading
          label: const Text('Create Organization'), // Button label
        ),
      ],
    );
  }
}
