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

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

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
            future: firestoreService
                .getOrgDevices(orgSelectorProvider.selectedOrgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading devices'));
              }
              final List<DocumentSnapshot> devicesDocs = snapshot.data!;

              return Column(
                children: [
                  SearchTextField(searchQuery: _searchQuery),
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
                                width: MediaQuery.of(context).size.width * 0.95,
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
                                      orgId: orgSelectorProvider.selectedOrgId,
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
              );
            },
          );
        },
      ),
    );
  }
}

class SearchTextField extends StatefulWidget {
  final ValueNotifier<String> searchQuery;

  SearchTextField({required this.searchQuery});

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              widget.searchQuery.value = '';
            },
          ),
        ),
        onChanged: (value) {
          widget.searchQuery.value = value;
        },
      ),
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
    return Consumer<FirestoreService>(
      builder: (context, firestoreService, child) {
        return StreamBuilder(
          stream: firestoreService.deviceCheckoutStatusStream(deviceId, orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading devices');
            }
            final isDeviceCheckedOut = snapshot.data as bool;

            return CustomCard(
              theme: theme,
              customCardLeading:
                  Icon(Icons.devices, color: theme.colorScheme.secondary),
              customCardTitle: Text(deviceSerialNumber),
              customCardTrailing: DeviceButton(
                deviceSerialNumber: deviceSerialNumber,
                orgId: orgId,
                isDeviceCheckedOut: isDeviceCheckedOut,
              ),
              onTapAction: () {},
            );
          },
        );
      },
    );
  }
}

class DeviceButton extends StatefulWidget {
  final String deviceSerialNumber;
  final String orgId;
  final bool isDeviceCheckedOut;

  const DeviceButton({
    super.key,
    required this.deviceSerialNumber,
    required this.orgId,
    required this.isDeviceCheckedOut,
  });

  @override
  _DeviceButtonState createState() => _DeviceButtonState();
}

class _DeviceButtonState extends State<DeviceButton> {
  var _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _onSubmit() async {
    setState(() => _isLoading = true);
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        widget.orgId,
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _onSubmit,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
      icon: _isLoading
          ? const CircularProgressIndicator()
          : const Icon(Icons.login),
      label: Text(widget.isDeviceCheckedOut ? 'Check In' : 'Check Out'),
    );
  }
}
