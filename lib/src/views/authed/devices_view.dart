import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestoreService.dart';
import '../../providers/orgSelectorProvider.dart';
import '../../widgets.dart';

class DevicesView extends StatelessWidget {
  DevicesView({Key? key, required this.firestoreService}) : super(key: key);

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
              return ScaffoldWithDrawer(
                  title: 'Devices', 
                  body: Column(
                    children: [
                    Center(child: Text('Devices Page')),
                    for (final deviceId in devicesUids) 
                      StreamBuilder(
                    stream: firestoreService.getDeviceSerialStream(deviceId, orgSelectorProvider.selectedOrgUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error loading devices');
                      }
                      final deviceSerial = snapshot.data ?? '';
                      print ('deviceSerial: $deviceSerial');
                      return ListTile(
                        title: Text(deviceSerial),
                        onTap: () {
                        /// implement device page routing  
                        },
                      );
                    },
                    ),
                    if (devicesUids.isEmpty) Text('No devices found'),
                    ],
                  )
              );
            });
      },
    );
  }
}