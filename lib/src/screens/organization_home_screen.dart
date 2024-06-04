import 'package:flutter/material.dart';

class OrganizationHomeScreen extends StatelessWidget {
  final String orgId;

  OrganizationHomeScreen({required this.orgId});

  static const routeName = '/orghome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Organization Home')),
      body: Center(child: Text('Welcome to your organization!')),
    );
  }
}
