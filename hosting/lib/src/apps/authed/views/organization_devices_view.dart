import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/providers/firestoreService.dart';

import '../../../shared/providers/orgSelectorChangeNotifier.dart';
import '../../../shared/widgets.dart';

class OrganizationDevicesView extends StatelessWidget {
  OrganizationDevicesView({super.key});
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      drawer: const AuthedDrawer(),
      body: Consumer2<OrgSelectorChangeNotifier, FirestoreService>(
        builder: (context, orgSelectorProvider, firestoreService, child) {
          return FutureBuilder<List<DocumentSnapshot>>(
            future: firestoreService.getOrgDevices(orgSelectorProvider.orgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<DocumentSnapshot> devicesDocs = snapshot.data!;

              return DeviceList(
                devicesDocs: devicesDocs,
              );
            },
          );
        },
      ),
    );
  }
}
