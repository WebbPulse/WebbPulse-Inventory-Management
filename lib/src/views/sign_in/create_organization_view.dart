import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firestoreProvider.dart';

class CreateOrganizationScreen extends StatelessWidget {
  CreateOrganizationScreen({super.key, required this.uid});

  static const routeName = '/create-organization';

  final TextEditingController _controller = TextEditingController();
  final String? uid; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Organization'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Organization Name',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final organizationCreationName = _controller.text;

                if (organizationCreationName.isNotEmpty) {
                  try {
                    // Get the instance of FirestoreService
                    await context.read<FirestoreProvider>().createOrganizationInFirestore(organizationCreationName, uid);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Organization created successfully!'),
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to create organization: $e'),
                    ));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please enter an organization name'),
                  ));
                }
              },
              child: Text('Create Organization'),
            ),
          ],
        ),
      ),
    );
  }
}
