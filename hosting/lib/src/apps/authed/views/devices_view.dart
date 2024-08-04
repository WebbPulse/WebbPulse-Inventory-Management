import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/firestoreService.dart';
import '../../../shared/providers/deviceCheckoutService.dart';
import '../../../shared/providers/orgSelectorChangeNotifier.dart';
import '../../../shared/widgets.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});
  static const routeName = '/devices';

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgSelectorChangeNotifier, FirestoreService,
        DeviceCheckoutService>(
      builder: (context, orgSelectorProvider, firestoreService,
          deviceCheckoutService, child) {
        return FutureBuilder<List<String>>(
            future: firestoreService
                .getDevicesUids(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<String> deviceIds = snapshot.data ?? [];
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Devices'),
                ),
                drawer: const AuthedDrawer(),
                body: Column(
                  children: [
                    const Center(child: Text('Device List')),
                    Expanded(
                      child: deviceIds.isNotEmpty
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: deviceIds.length,
                                itemBuilder: (context, index) {
                                  final deviceId = deviceIds[index];
                                  return DeviceCard(
                                    deviceId: deviceId,
                                    orgId: orgSelectorProvider.selectedOrgId,
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
    required this.orgId,
  });

  final String deviceId;
  final String orgId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<FirestoreService, DeviceCheckoutService>(
      builder: (context, firestoreService, deviceCheckoutService, child) {
        return StreamBuilder(
          stream: firestoreService.getDeviceDataStream(deviceId, orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading devices');
            }
            Map<String, dynamic> deviceData = snapshot.data!;
            String deviceSerial = deviceData['serial'] ?? '';
            bool deviceIsCheckedOut = deviceData['isCheckedOut'] ?? false;

            return CustomCard(
                theme: theme,
                customCardLeading:
                    Icon(Icons.devices, color: theme.colorScheme.secondary),
                titleText: deviceSerial,
                customCardTrailing: ElevatedButton(
                  child: Text(deviceIsCheckedOut ? 'Check In' : 'Check Out'),
                  onPressed: () {
                    deviceCheckoutService.handleDeviceCheckout(
                        context, deviceSerial, orgId);
                  },
                ),
                onTapAction: () {});
          },
        );
      },
    );
  }
}
