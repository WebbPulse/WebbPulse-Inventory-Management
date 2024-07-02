import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/firestoreService.dart';
import '../../../shared/providers/orgSelectorProvider.dart';
import '../../../shared/widgets.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key, required this.firestoreService});

  final FirestoreService firestoreService;
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    // The email is now directly available to use
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) {
        return StreamBuilder<List<String>>(
            stream: firestoreService
                .getDevicesUidsStream(orgSelectorProvider.selectedOrgUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading devices');
              }
              final devicesUids = snapshot.data ?? [];
              return Scaffold(
                  appBar: AppBar(
                    title: const Text('Devices Page'),
                  ),
                  drawer: const AuthedDrawer(),
                  body: Column(
                    children: [
                      const Center(child: Text('Devices Page')),
                      for (final deviceId in devicesUids)
                        StreamBuilder(
                          stream: firestoreService.getDeviceSerialStream(
                              deviceId, orgSelectorProvider.selectedOrgUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text('Error loading devices');
                            }
                            final deviceSerial = snapshot.data ?? '';
                            return ListTile(
                              title: Text(deviceSerial),
                              onTap: () {
                                /// implement device page routing
                              },
                            );
                          },
                        ),
                      if (devicesUids.isEmpty) const Text('No devices found'),
                    ],
                  ));
            });
      },
    );
  }
}
