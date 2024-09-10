import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/providers/firestore_read_service.dart';

import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/widgets.dart';

class OrgDeviceListView extends StatelessWidget {
  const OrgDeviceListView({super.key});
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: OrgNameAppBar(
        titleSuffix: 'Devices',
        actions: [
          ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AddDeviceAlertDialog();
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surface.withOpacity(0.95),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.all(16.0),
                      ),
                      label: const Text('Add New Device'),
                      icon: const Icon(Icons.add),
                    )
        ],
      ),
      drawer: const AuthedDrawer(),
      body: Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(
        builder: (context, orgSelectorProvider, firestoreService, child) {
          return StreamBuilder<List<DocumentSnapshot>>(
            stream: firestoreService
                .getOrgDevicesDocuments(orgSelectorProvider.orgId),
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
