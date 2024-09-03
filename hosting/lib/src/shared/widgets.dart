// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

import 'providers/firestore_read_service.dart';
import 'providers/device_checkout_service.dart';
import 'providers/org_selector_change_notifier.dart';
import 'providers/authentication_change_notifier.dart';

import '../apps/authed/views/org_selection_view.dart';

import '../apps/authed/views/profile_settings_view.dart';
import '../apps/authed/views/org_selected/device_checkout_view.dart';
import '../apps/authed/views/org_selected/org_device_list_view.dart';
import '../apps/authed/views/org_selected/org_member_list_view.dart';
import '../apps/authed/views/org_selected/org_settings_view.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ProfileAvatar extends StatefulWidget {
  final String? photoUrl;

  const ProfileAvatar({super.key, this.photoUrl});

  @override
  ProfileAvatarState createState() => ProfileAvatarState();
}

class ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 75,
      backgroundColor:
          _hasError ? Theme.of(context).colorScheme.onSecondary : null,
      backgroundImage: !_hasError && widget.photoUrl != null
          ? NetworkImage(widget.photoUrl!)
          : null,
      onBackgroundImageError: !_hasError
          ? (exception, stackTrace) {
              // Schedule the setState to happen after the current frame
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                  });
                }
              });
            }
          : null,
      child: _hasError
          ? Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.secondary,
            )
          : null,
    );
  }
}

class AuthClaimChecker extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, dynamic> claims)
      builder;

  const AuthClaimChecker({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationChangeNotifier>(
      builder: (context, authenticationChangeNotifier, child) {
        final user = authenticationChangeNotifier.user;

        if (user == null) {
          return const Center(child: Text('User not signed in'));
        }

        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading user data'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No token data available'));
            }

            final claims = snapshot.data!.claims;

            return builder(context, claims!);
          },
        );
      },
    );
  }
}

class OrgDocumentStreamBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DocumentSnapshot orgDocument)
      builder;

  const OrgDocumentStreamBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(builder:
        (context, firestoreReadService, orgSelectorChangeNotifier, child) {
      return StreamBuilder<DocumentSnapshot>(
        stream: firestoreReadService
            .getOrgDocument(orgSelectorChangeNotifier.orgId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
            return const CircularProgressIndicator();
          }
          DocumentSnapshot orgDocument = snapshot.data!;

          return builder(context, orgDocument);
        },
      );
    });
  }
}

class OrgNameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleSuffix;
  final List<Widget> actions;
  final Widget? leading;

  const OrgNameAppBar({
    super.key,
    this.titleSuffix = '',
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return OrgDocumentStreamBuilder(
      builder: (context, orgDocument) {
        final String orgName = orgDocument['orgName'] ?? '';

        return AppBar(
          title: Text('$orgName $titleSuffix'),
          actions: actions,
          leading: leading,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AuthedDrawer extends StatelessWidget {
  const AuthedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthClaimChecker(builder: (context, userClaims) {
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
                Navigator.pushNamed(context, DeviceCheckoutView.routeName);
              },
            ),
            ListTile(
              title: const Text('Devices'),
              onTap: () {
                Navigator.pushNamed(context, OrgDeviceListView.routeName);
              },
            ),
            ListTile(
              title: const Text('Users'),
              onTap: () {
                Navigator.pushNamed(context, OrgMemberListView.routeName);
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, ProfileSettingsView.routeName);
              },
            ),
            if (userClaims[
                    'org_admin_${Provider.of<OrgSelectorChangeNotifier>(context).orgId}'] ==
                true)
              ListTile(
                title: const Text('Organization Settings'),
                onTap: () {
                  Navigator.pushNamed(context, OrgSettingsView.routeName);
                },
              ),
            ListTile(
              title: const Text('My Organizations'),
              onTap: () {
                Navigator.pushNamed(context, OrgSelectionView.routeName);
              },
            ),
          ],
        ),
      );
    });
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

class SmallLayoutBuilder extends StatelessWidget {
  const SmallLayoutBuilder({super.key, required this.childWidget});
  final Widget childWidget;

  @override
  Widget build(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0.0;
    final topPadding = MediaQuery.of(context).padding.top;
    final availableHeight =
        MediaQuery.of(context).size.height - appBarHeight - topPadding;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight,
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double widthFactor;
            if (constraints.maxWidth < 600) {
              widthFactor = 0.9; // 90% of the width for narrow screens
            } else if (constraints.maxWidth < 1200) {
              widthFactor = 0.5; // 50% of the width for medium screens
            } else {
              widthFactor = 0.2; // 20% of the width for large screens
            }
            return SizedBox(
              width: constraints.maxWidth * widthFactor,
              child: childWidget,
            );
          },
        ),
      ),
    );
  }
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
                  final lowerCaseQuery =
                      query.toLowerCase(); // Convert query to lowercase
                  final filteredDevices = devicesDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Convert the boolean value to "checked in" or "checked out"
                    final isDeviceCheckedOut =
                        data['isDeviceCheckedOut'] == true
                            ? 'checked out'
                            : 'checked in';
                    final deviceSerialNumber =
                        (data['deviceSerialNumber'] ?? '')
                            .toString()
                            .toLowerCase();

                    return deviceSerialNumber.contains(lowerCaseQuery) ||
                        isDeviceCheckedOut.contains(lowerCaseQuery);
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

                              return DeviceCard(
                                deviceData: deviceData,
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

  const SerialSearchTextField({super.key, required this.searchQuery});

  @override
  SerialSearchTextFieldState createState() => SerialSearchTextFieldState();
}

class SerialSearchTextFieldState extends State<SerialSearchTextField> {
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
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
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
    required this.deviceData,
  });

  final Map<String, dynamic> deviceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String deviceId = deviceData['deviceId'];
    final String deviceSerialNumber = deviceData['deviceSerialNumber'];
    final bool deviceDeleted = deviceData['deviceDeleted'] ?? false;
    if (deviceDeleted) {
      return const SizedBox.shrink();
    }
    return Consumer4<FirestoreReadService, DeviceCheckoutService,
        OrgSelectorChangeNotifier, FirebaseFunctions>(
      builder: (context, firestoreService, deviceCheckoutService,
          orgSelectorChangeNotifier, firebaseFunctions, child) {
        return StreamBuilder(
          stream: firestoreService.getOrgDeviceDocument(
              deviceId, orgSelectorChangeNotifier.orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading devices');
            }
            final deviceData = snapshot.data?.data() as Map<String, dynamic>;
            final orgMemberId = deviceData['deviceCheckedOutBy'];

            return StreamBuilder<DocumentSnapshot?>(
                stream: firestoreService.getOrgMemberDocument(
                    orgSelectorChangeNotifier.orgId, orgMemberId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text('Error loading org member data');
                  } else if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.data() == null) {
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
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        firebaseFunctions
                                            .httpsCallable(
                                                'delete_device_callable')
                                            .call({
                                          'orgId':
                                              orgSelectorChangeNotifier.orgId,
                                          'deviceId': deviceId,
                                        });
                                      },
                                      icon: const Icon(Icons.delete),
                                      label: const Wrap(children: [
                                        Text('Delete Device'),
                                      ]),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.all(16.0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
                        customCardTitle: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    children: [
                                      Text(deviceSerialNumber,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        firebaseFunctions
                                            .httpsCallable(
                                                'delete_device_callable')
                                            .call({
                                          'orgId':
                                              orgSelectorChangeNotifier.orgId,
                                          'deviceId': deviceId,
                                        });
                                      },
                                      icon: const Icon(Icons.delete),
                                      label: const Wrap(children: [
                                        Text('Delete Device'),
                                      ]),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.all(16.0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DeviceCheckoutButton(
                                      deviceSerialNumber: deviceSerialNumber,
                                      isDeviceCheckedOut:
                                          deviceData['isDeviceCheckedOut'],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        customCardTrailing: null,
                        onTapAction: () {},
                      );
                    });
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
                                      style: const TextStyle(
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      firebaseFunctions
                                          .httpsCallable(
                                              'delete_device_callable')
                                          .call({
                                        'orgId':
                                            orgSelectorChangeNotifier.orgId,
                                        'deviceId': deviceId,
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Wrap(children: [
                                      Text('Delete Device'),
                                    ]),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.all(16.0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                      customCardTitle: Row(
                        children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    children: [
                                      Text(deviceSerialNumber,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Wrap(
                                    children: [
                                      Text('Checked Out By: ',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Text(
                                          orgMemberData['orgMemberDisplayName'],
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
                                  )
                                ]),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      firebaseFunctions
                                          .httpsCallable(
                                              'delete_device_callable')
                                          .call({
                                        'orgId':
                                            orgSelectorChangeNotifier.orgId,
                                        'deviceId': deviceId,
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Wrap(children: [
                                      Text('Delete Device'),
                                    ]),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.all(16.0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DeviceCheckoutButton(
                                    deviceSerialNumber: deviceSerialNumber,
                                    isDeviceCheckedOut:
                                        deviceData['isDeviceCheckedOut'],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      customCardTrailing: null,
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
  DeviceCheckoutButtonState createState() => DeviceCheckoutButtonState();
}

class DeviceCheckoutButtonState extends State<DeviceCheckoutButton> {
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
        Provider.of<AuthenticationChangeNotifier>(context, listen: false)
            .user!
            .uid;
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _onSubmit,
      style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          padding: const EdgeInsets.all(16.0)),
      icon: _isLoading
          ? const CircularProgressIndicator()
          : const Icon(Icons.login),
      label: Text(widget.isDeviceCheckedOut ? 'Check In' : 'Check Out'),
    );
  }
}
