// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'providers/firestoreService.dart';
import 'providers/deviceCheckoutService.dart';
import 'providers/orgSelectorChangeNotifier.dart';
import 'providers/authenticationChangeNotifier.dart';

import '../apps/authed/views/org_selection_view.dart';

import '../apps/authed/views/profile_view.dart';
import '../apps/authed/views/settings_view.dart';
import '../apps/authed/views/checkout_view.dart';
import '../apps/authed/views/organization_devices_view.dart';
import '../apps/authed/views/users_view.dart';

class AuthedDrawer extends StatelessWidget {
  const AuthedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text('Menu'),
          ),
          ListTile(
            title: const Text('Checkout'),
            onTap: () {
              Navigator.pushNamed(context, CheckoutView.routeName);
            },
          ),
          ListTile(
            title: const Text('Devices'),
            onTap: () {
              Navigator.pushNamed(context, OrganizationDevicesView.routeName);
            },
          ),
          ListTile(
            title: const Text('Users'),
            onTap: () {
              Navigator.pushNamed(context, UsersView.routeName);
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, SettingsView.routeName);
            },
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, ProfileView.routeName);
            },
          ),
          ListTile(
            title: const Text('Organizations'),
            onTap: () {
              Navigator.pushNamed(context, OrgSelectionView.routeName);
            },
          ),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header(this.heading, {super.key});
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          heading,
          style: const TextStyle(fontSize: 24),
        ),
      );
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 18),
        ),
      );
}

class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail, {super.key});
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: 18),
            )
          ],
        ),
      );
}

class CustomCard extends StatelessWidget {
  const CustomCard(
      {super.key,
      required this.theme,
      required this.customCardLeading,
      required this.customCardTitle,
      required this.customCardTrailing,
      required this.onTapAction});
  final ThemeData theme;
  final dynamic customCardLeading;
  final dynamic customCardTitle;
  final dynamic customCardTrailing;
  final dynamic onTapAction;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          tileColor: theme.colorScheme.secondary.withOpacity(0),
          leading: customCardLeading,
          title: customCardTitle,
          trailing: customCardTrailing,
          onTap: onTapAction,
        ),
      );
}

class CustomLayoutBuilder extends StatelessWidget {
  const CustomLayoutBuilder({super.key, required this.childWidget});
  final Widget childWidget;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double widthFactor;
              if (constraints.maxWidth < 600) {
                widthFactor = 0.9; // 90% of the width for narrow screens
              } else if (constraints.maxWidth < 1200) {
                widthFactor = 0.5; // 70% of the width for medium screens
              } else {
                widthFactor = 0.2; // 50% of the width for large screens
              }
              return SizedBox(
                  width: constraints.maxWidth * widthFactor,
                  child: childWidget);
            },
          ),
        ),
      );
}

class DeviceList extends StatelessWidget {
  DeviceList({
    super.key,
    required this.devicesDocs,
  });

  final List<DocumentSnapshot> devicesDocs;
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgSelectorChangeNotifier>(
      builder: (context, orgSelectorProvider, child) {
        return Column(
          children: [
            SerialSearchTextField(searchQuery: _searchQuery),
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
                                orgId: orgSelectorProvider.orgId,
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
  }
}

class SerialSearchTextField extends StatefulWidget {
  final ValueNotifier<String> searchQuery;

  const SerialSearchTextField({required this.searchQuery});

  @override
  _SerialSearchTextFieldState createState() => _SerialSearchTextFieldState();
}

class _SerialSearchTextFieldState extends State<SerialSearchTextField> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

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
    return Consumer2<FirestoreService, DeviceCheckoutService>(
      builder: (context, firestoreService, deviceCheckoutService, child) {
        return StreamBuilder(
          stream: firestoreService.getOrgDevice(deviceId, orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading devices');
            }
            final deviceData = snapshot.data?.data() as Map<String, dynamic>;
            final orgMemberId = deviceData['deviceCheckedOutBy'];

            return StreamBuilder<DocumentSnapshot?>(
                stream: firestoreService.getOrgMember(orgId, orgMemberId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text('Error loading org member data');
                  } else if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.data() == null) {
                    return CustomCard(
                      theme: theme,
                      customCardLeading: Icon(Icons.devices,
                          color: theme.colorScheme.secondary),
                      customCardTitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: [
                                Text(deviceSerialNumber,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ]),
                      customCardTrailing: DeviceCheckoutButton(
                        deviceSerialNumber: deviceSerialNumber,
                        isDeviceCheckedOut: deviceData['isDeviceCheckedOut'],
                      ),
                      onTapAction: () {},
                    );
                  }

                  Map<String, dynamic> orgMemberData =
                      snapshot.data?.data() as Map<String, dynamic>;

                  final Timestamp deviceCheckedOutAtTimestamp =
                      deviceData['deviceCheckedOutAt'];
                  final DateTime deviceCheckedOutAt =
                      deviceCheckedOutAtTimestamp.toDate();
                  final String deviceCheckedOutAtFormatted =
                      DateFormat('yyyy-MM-dd kk:mm a')
                          .format(deviceCheckedOutAt);

                  return LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      return CustomCard(
                        theme: theme,
                        customCardLeading: null,
                        customCardTitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.devices,
                                  color: theme.colorScheme.secondary),
                              Wrap(
                                children: [
                                  Text(deviceSerialNumber,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text('Checked Out By: ',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(orgMemberData['orgMemberDisplayName'],
                                      style: theme.textTheme.labelSmall),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text('Checked Out On: ',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(deviceCheckedOutAtFormatted,
                                      style: theme.textTheme.labelSmall),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  DeviceCheckoutButton(
                                    deviceSerialNumber: deviceSerialNumber,
                                    isDeviceCheckedOut:
                                        deviceData['isDeviceCheckedOut'],
                                  ),
                                ],
                              ),
                            ]),
                        customCardTrailing: null,
                        onTapAction: () {},
                      );
                    }
                    return CustomCard(
                      theme: theme,
                      customCardLeading: Icon(Icons.devices,
                          color: theme.colorScheme.secondary),
                      customCardTitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: [
                                Text(deviceSerialNumber,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Wrap(
                              children: [
                                Text('Checked Out By: ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                Text(orgMemberData['orgMemberDisplayName'],
                                    style: theme.textTheme.labelSmall),
                              ],
                            ),
                            Wrap(
                              children: [
                                Text('Checked Out On: ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                Text(deviceCheckedOutAtFormatted,
                                    style: theme.textTheme.labelSmall),
                              ],
                            )
                          ]),
                      customCardTrailing: DeviceCheckoutButton(
                        deviceSerialNumber: deviceSerialNumber,
                        isDeviceCheckedOut: deviceData['isDeviceCheckedOut'],
                      ),
                      onTapAction: () {},
                    );
                  });
                });
          },
        );
      },
    );
  }
}

class DeviceCheckoutButton extends StatefulWidget {
  final String deviceSerialNumber;
  final bool isDeviceCheckedOut;

  const DeviceCheckoutButton({
    super.key,
    required this.deviceSerialNumber,
    required this.isDeviceCheckedOut,
  });

  @override
  _DeviceCheckoutButtonState createState() => _DeviceCheckoutButtonState();
}

class _DeviceCheckoutButtonState extends State<DeviceCheckoutButton> {
  var _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _onSubmit() async {
    setState(() => _isLoading = true);
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckedOutBy =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false).uid;
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy!,
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
