import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/providers/firestoreService.dart';
import '../../../shared/providers/deviceCheckoutService.dart';
import '../../../shared/providers/orgSelectorChangeNotifier.dart';
import '../../../shared/widgets.dart';

class DevicesView extends StatelessWidget {
  DevicesView({super.key});
  static const routeName = '/devices';

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrgSelectorChangeNotifier, FirestoreService>(
      builder: (context, orgSelectorProvider, firestoreService, child) {
        return FutureBuilder<List<DocumentSnapshot>>(
            future: firestoreService
                .getOrgDevices(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<DocumentSnapshot> devicesDocs = snapshot.data!;

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Devices'),
                ),
                drawer: const AuthedDrawer(),
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by Serial',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _searchQuery.value = value;
                        },
                      ),
                    ),
                    const Center(child: Text('Device List')),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (context, query, child) {
                          final filteredDevices = devicesDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final serial = data['deviceSerialNumber'] ?? '';
                            return serial.contains(query);
                          }).toList();

                          return filteredDevices.isNotEmpty
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.95,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredDevices.length,
                                    itemBuilder: (context, index) {
                                      Map<String, dynamic> deviceData =
                                          filteredDevices[index].data()
                                              as Map<String, dynamic>;
                                      final deviceId = deviceData['deviceId'];
                                      final deviceSerialNumber =
                                          deviceData['deviceSerialNumber'];
                                      return DeviceCard(
                                        deviceId: deviceId,
                                        orgId:
                                            orgSelectorProvider.selectedOrgId,
                                        deviceSerialNumber: deviceSerialNumber,
                                      );
                                    },
                                  ),
                                )
                              : const Center(child: Text('No devices found'));
                        },
                      ),
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
    required this.deviceSerialNumber,
  });

  final String deviceId;
  final String orgId;
  final String deviceSerialNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<FirestoreService, DeviceCheckoutService>(
      builder: (context, firestoreService, deviceCheckoutService, child) {
        return StreamBuilder(
          stream: firestoreService.deviceCheckoutStatusStream(deviceId, orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading devices');
            }
            final deviceIsCheckedOut = snapshot.data as bool;

            return CustomCard(
                theme: theme,
                customCardLeading:
                    Icon(Icons.devices, color: theme.colorScheme.secondary),
                customCardTitle: Text(deviceSerialNumber),
                customCardTrailing: DeviceButton(
                  deviceSerialNumber: deviceSerialNumber,
                  orgId: orgId,
                  deviceCheckoutService: deviceCheckoutService,
                  deviceIsCheckedOut: deviceIsCheckedOut,
                ),
                onTapAction: () {});
          },
        );
      },
    );
  }
}

class DeviceButton extends StatefulWidget {
  final String deviceSerialNumber;
  final String orgId;
  final DeviceCheckoutService deviceCheckoutService;
  final bool deviceIsCheckedOut;
  
  const DeviceButton({
    super.key,
    required this.deviceSerialNumber,
    required this.orgId,
    required this.deviceCheckoutService,
    required this.deviceIsCheckedOut,
  });
  @override
  _DeviceButtonState createState() => _DeviceButtonState();
}

class _DeviceButtonState extends State<DeviceButton> {
  var _isLoading = false;
  
  @override
  void dispose() {
    // Add any resource cleanup code here if needed in the future
    super.dispose();
  }

  void _onSubmit() {
    setState(() => _isLoading = true);
    widget.deviceCheckoutService.handleDeviceCheckout(
      context, widget.deviceSerialNumber, widget.orgId,
    ).then((_) {
      setState(() => _isLoading = false);
    });
    Future.delayed(
      const Duration(seconds: 2),
      () => setState(() => _isLoading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _onSubmit,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
      icon: _isLoading
          ? const CircularProgressIndicator()
          : const Icon(Icons.login),
      label: Text(widget.deviceIsCheckedOut ? 'Check In' : 'Check Out'),
    );
  }
}
