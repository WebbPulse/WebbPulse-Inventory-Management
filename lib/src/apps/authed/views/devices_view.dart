import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/firestoreService.dart';
import '../../../shared/services/deviceCheckoutService.dart';
import '../../../shared/providers/orgSelectorProvider.dart';
import '../../../shared/widgets.dart';

class DevicesView extends StatelessWidget {
  const DevicesView(
      {super.key,
      required this.firestoreService,
      required this.deviceCheckoutService});

  final FirestoreService firestoreService;
  final DeviceCheckoutService deviceCheckoutService;
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<OrgSelectorProvider>(
      builder: (context, orgSelectorProvider, child) {
        return FutureBuilder<List<String>>(
            future: firestoreService
                .getDevicesUids(orgSelectorProvider.selectedOrgUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<String> devicesUids = snapshot.data ?? [];
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Devices'),
                ),
                drawer: const AuthedDrawer(),
                body: Column(
                  children: [
                    const Center(child: Text('Device List')),
                    Expanded(
                      child: devicesUids.isNotEmpty
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: devicesUids.length,
                                itemBuilder: (context, index) {
                                  final deviceId = devicesUids[index];
                                  return DeviceCard(
                                    deviceId: deviceId,
                                    firestoreService: firestoreService,
                                    deviceCheckoutService:
                                        deviceCheckoutService,
                                    orgUid: orgSelectorProvider.selectedOrgUid,
                                    theme: theme,
                                  );
                                },
                              ),
                            )
                          : const Center(child: Text('No devices found')),
                    ),
                  ],
                ),
              );
            });
      },
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.deviceId,
    required this.firestoreService,
    required this.deviceCheckoutService,
    required this.orgUid,
    required this.theme,
  });

  final String deviceId;
  final FirestoreService firestoreService;
  final DeviceCheckoutService deviceCheckoutService;
  final String orgUid;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.getDeviceDataStream(deviceId, orgUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading devices');
        }
        Map<String, dynamic> deviceData = snapshot.data!;
        String deviceSerial = deviceData['serial'] ?? '';
        bool deviceIsCheckedOut = deviceData['isCheckedOut'] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            tileColor: theme.colorScheme.secondary.withOpacity(0.1),
            leading: Icon(Icons.devices, color: theme.colorScheme.secondary),
            title: Text(
              deviceSerial,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            trailing: ElevatedButton(
              child: Text(deviceIsCheckedOut ? 'Check In' : 'Check Out'),
              onPressed: () {
                deviceCheckoutService.handleDeviceCheckout(
                    context, deviceSerial, orgUid);
              },
            ),
            onTap: () {
              // implement device page routing
            },
          ),
        );
      },
    );
  }
}
