import 'package:flutter/material.dart';


class CreateOrganizationScreen extends StatelessWidget {
  CreateOrganizationScreen({super.key});
  static const routeName = '/create-organization';


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
              decoration: InputDecoration(
                labelText: 'Organization Name',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Create the organization
              },
              child: Text('Create Organization'),
            ),
          ],
        ),
      ),
    );
  }
}