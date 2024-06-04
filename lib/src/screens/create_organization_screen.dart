import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'organization_home_screen.dart';

class CreateOrganizationScreen extends StatefulWidget {
  @override
  _CreateOrganizationScreenState createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String _orgName = '';

  Future<void> _createOrganization() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.createOrganization(_orgName, user);

        // Navigate to the main app screen or organization-specific screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrganizationHomeScreen(orgId: user.uid)), // Adjust based on how you identify the organization
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Organization')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Organization Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organization name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _orgName = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createOrganization,
                child: Text('Create Organization'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
