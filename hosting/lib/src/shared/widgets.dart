// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:webbcheck/src/shared/helpers/async_context_helpers.dart';
import 'package:universal_html/html.dart' as html; // Universal web support
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

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
      final orgId = Provider.of<OrgSelectorChangeNotifier>(context).orgId;
      final authenticationChangeNotifier =
          Provider.of<AuthenticationChangeNotifier>(context);

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
            // Only show these items if orgId is not empty
            if (orgId.isNotEmpty) ...[
              if (userClaims['org_admin_$orgId'] == true)
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Organization Settings'),
                  onTap: () {
                    Navigator.pushNamed(context, OrgSettingsView.routeName);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text('Checkout'),
                onTap: () {
                  Navigator.pushNamed(context, DeviceCheckoutView.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Devices'),
                onTap: () {
                  Navigator.pushNamed(context, OrgDeviceListView.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Users'),
                onTap: () {
                  Navigator.pushNamed(context, OrgMemberListView.routeName);
                },
              ),
            ],
            if (userClaims['org_deskstation_$orgId'] != true)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, ProfileSettingsView.routeName);
                },
              ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('My Organizations'),
              onTap: () {
                Navigator.pushNamed(context, OrgSelectionView.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                authenticationChangeNotifier.signOutUser();
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
              widthFactor = 0.95; // 90% of the width for narrow screens
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
    return AuthClaimChecker(builder: (context, userClaims) {
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
              final orgId = orgSelectorChangeNotifier.orgId;
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
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    runSpacing: 8,
                                    children: [
                                      DeviceCheckoutButton(
                                        deviceSerialNumber: deviceSerialNumber,
                                        isDeviceCheckedOut:
                                            deviceData['isDeviceCheckedOut'],
                                      ),
                                      const SizedBox(width: 8),
                                      if (userClaims['org_admin_$orgId'] ==
                                          true)
                                        DeleteDeviceButton(
                                            deviceData: deviceData),
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
                                      DeviceCheckoutButton(
                                        deviceSerialNumber: deviceSerialNumber,
                                        isDeviceCheckedOut:
                                            deviceData['isDeviceCheckedOut'],
                                      ),
                                      const SizedBox(width: 8),
                                      if (userClaims['org_admin_$orgId'] ==
                                          true)
                                        DeleteDeviceButton(
                                            deviceData: deviceData),
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
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  runSpacing: 8,
                                  children: [
                                    DeviceCheckoutButton(
                                      deviceSerialNumber: deviceSerialNumber,
                                      isDeviceCheckedOut:
                                          deviceData['isDeviceCheckedOut'],
                                    ),
                                    const SizedBox(width: 8),
                                    if (userClaims['org_admin_$orgId'] == true)
                                      DeleteDeviceButton(
                                          deviceData: deviceData),
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
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        Text(
                                            orgMemberData[
                                                'orgMemberDisplayName'],
                                            style: theme.textTheme.labelSmall),
                                      ],
                                    ),
                                    Wrap(
                                      children: [
                                        Text('Checked Out On: ',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
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
                                    DeviceCheckoutButton(
                                      deviceSerialNumber: deviceSerialNumber,
                                      isDeviceCheckedOut:
                                          deviceData['isDeviceCheckedOut'],
                                    ),
                                    const SizedBox(width: 8),
                                    if (userClaims['org_admin_$orgId'] == true)
                                      DeleteDeviceButton(
                                          deviceData: deviceData),
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
    });
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
  late TextEditingController _userSearchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userSearchController = TextEditingController();
    _userSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _userSearchController.text;
    });
  }

  void _onSubmit(bool checkOut) async {
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
        checkOut, // Pass the checkout state (true for checkout, false for check-in)
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSubmitAdminAndDeskstation(
      bool checkOut, String deviceCheckedOutBy) async {
    setState(() => _isLoading = true);
    final orgId =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
    final deviceCheckoutService =
        Provider.of<DeviceCheckoutService>(context, listen: false);
    try {
      await deviceCheckoutService.handleDeviceCheckout(
        context,
        widget.deviceSerialNumber,
        orgId,
        deviceCheckedOutBy,
        checkOut, // Pass the boolean for checkout or check-in
      );
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAdminDialog(bool checkOut, String orgId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        ThemeData theme = Theme.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(checkOut
                  ? 'Confirm Check-out User'
                  : 'Confirm Check-in User'),
              content:
                  Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
                      builder: (context, firestoreReadService,
                          orgSelectorChangeNotifier, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkOut
                          ? 'Select the user to check-out this device.'
                          : 'Select the user to check-in this device.',
                    ),
                    TextField(
                      controller: _userSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Search User',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    StreamBuilder<List<DocumentSnapshot>>(
                        stream: firestoreReadService.getOrgMembersDocuments(
                            orgSelectorChangeNotifier.orgId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading users'));
                          }
                          final List<DocumentSnapshot> orgMemberDocs =
                              snapshot.data!;

                          // Filter the list based on the search query
                          final filteredDocs = orgMemberDocs.where((doc) {
                            final name = doc['orgMemberDisplayName']
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery.toLowerCase());
                          }).toList();

                          if (filteredDocs.isNotEmpty) {
                            return Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: filteredDocs.map((orgMemberDoc) {
                                    return ListTile(
                                      title: Text(
                                          orgMemberDoc['orgMemberDisplayName']),
                                      subtitle:
                                          Text(orgMemberDoc['orgMemberEmail']),
                                      onTap: () {
                                        _onSubmitAdminAndDeskstation(
                                          checkOut,
                                          orgMemberDoc.id,
                                        );
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          } else {
                            return const Column(
                              children: [
                                SizedBox(
                                  height: 16,
                                ),
                                Center(
                                  child: Text('No users found.'),
                                ),
                              ],
                            );
                          }
                        }),
                  ],
                );
              }),
              actions: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
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
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AuthClaimChecker(builder: (context, userClaims) {
      final orgId =
          Provider.of<OrgSelectorChangeNotifier>(context, listen: false).orgId;
      // Safely check if the roles exist and their values are true
      bool isAdminOrDeskstation = (userClaims['org_admin_$orgId'] == true) ||
          (userClaims['org_deskstation_$orgId'] == true);

      return ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  if (isAdminOrDeskstation && !widget.isDeviceCheckedOut) {
                    _showAdminDialog(true, orgId);
                  } else {
                    _onSubmit(!widget.isDeviceCheckedOut);
                  }
                },
          icon: _isLoading
              ? const CircularProgressIndicator()
              : Icon(widget.isDeviceCheckedOut ? Icons.logout : Icons.login),
          label: Text(widget.isDeviceCheckedOut
              ? 'Check-in Device'
              : 'Check-out Device'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ));
    });
  }
}

class DeleteDeviceButton extends StatefulWidget {
  const DeleteDeviceButton({
    super.key,
    required this.deviceData,
  });

  final Map<String, dynamic> deviceData;

  @override
  State<DeleteDeviceButton> createState() => _DeleteDeviceButtonState();
}

class _DeleteDeviceButtonState extends State<DeleteDeviceButton> {
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPressed() async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      String deviceId = widget.deviceData['deviceId'];
      await firebaseFunctions.httpsCallable('delete_device_callable').call({
        'orgId': orgSelectorProvider.orgId,
        'deviceId': deviceId,
      });
      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Device deleted successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to delete device: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FirebaseFunctions, OrgSelectorChangeNotifier,
            AuthenticationChangeNotifier>(
        builder: (context, firebaseFunctions, orgSelectorChangeNotifier,
            authenticationChangeNotifier, child) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _onPressed,
        icon: _isLoading
            ? const CircularProgressIndicator()
            : const Icon(Icons.delete),
        label: Wrap(children: [
          Text(
            'Delete Device',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ]),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.red,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.all(16.0),
        ),
      );
    });
  }
}

class AddDeviceAlertDialog extends StatefulWidget {
  const AddDeviceAlertDialog({super.key});

  @override
  AddDeviceAlertDialogState createState() => AddDeviceAlertDialogState();
}

class AddDeviceAlertDialogState extends State<AddDeviceAlertDialog> {
  late TextEditingController _deviceSerialNumberController;
  var _isLoading = false;
  final String csvTemplate =
      "Device Serial Number\nAAAA-AAAA-AAAA\nBBBB-BBBB-BBBB";

  @override
  void initState() {
    super.initState();
    _deviceSerialNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _deviceSerialNumberController.dispose();
    super.dispose();
  }

  // Method to handle both Web and Mobile/Other platforms
  Future<void> downloadCSV() async {
    if (kIsWeb) {
      // Web platform: Trigger CSV download using HTML anchor element
      downloadCSVForWeb();
    } else {
      // Mobile/Desktop platform: Save CSV to file and notify user
      await downloadCSVForMobile();
    }
  }

  // Method to download CSV for Web using universal_html
  void downloadCSVForWeb() {
    // Create a Blob (binary large object) for the CSV content
    final bytes = utf8.encode(csvTemplate); // CSV data as bytes
    final blob = html.Blob([bytes], 'text/csv'); // Create a Blob of type CSV

    // Create an anchor element and trigger the download
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "device_template.csv") // Specify the file name
      ..click(); // Trigger the download
    html.Url.revokeObjectUrl(url); // Revoke the URL to free up memory
  }

  // Method to download CSV for Mobile/Desktop platforms
  Future<void> downloadCSVForMobile() async {
    // Request storage permissions (only for Android/iOS)
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Get the directory to save the file
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        String filePath = '${directory.path}/user_template.csv';

        // Write the CSV content to the file
        io.File file = io.File(filePath);
        await file.writeAsString(csvTemplate);

        // Notify user that the file has been saved
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'CSV Template saved to $filePath');
      } else {
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to get storage directory');
      }
    } else {
      AsyncContextHelpers.showSnackBarIfMounted(context, 'Permission denied');
    }
  }

  Future<void> _submitDeviceSerialNumbers(
      List<String> deviceSerialNumbers) async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseFunctions.httpsCallable('create_device_callable').call({
        "deviceSerialNumbers": deviceSerialNumbers,
        "orgId": orgSelectorProvider.orgId,
      });
      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Devices created successfully');
      AsyncContextHelpers.popContextIfMounted(context);
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to create Devices: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSubmitSingleEmail() async {
    final deviceSerialNumber = _deviceSerialNumberController.text;
    if (deviceSerialNumber.isNotEmpty) {
      await _submitDeviceSerialNumbers([deviceSerialNumber]);
    }
  }

  // Method to parse CSV file
  void _onCsvFileSelected() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String content = '';

      // Handle file content differently for web and mobile
      if (kIsWeb) {
        // Web: Use bytes
        final file = result.files.first;
        content = utf8.decode(file.bytes!);
      } else {
        // Mobile: Use file path
        final path = result.files.single.path;
        if (path != null) {
          final file = io.File(path);
          content = await file.readAsString();
        }
      }

      // Split the CSV content by line breaks
      List<String> lines = content.split(RegExp(r'[\r\n]+'));

      // Skip the first line (header) and process the remaining lines
      if (lines.isNotEmpty) {
        lines = lines.sublist(1);
      }

      // Extract the emails, exclude empty lines
      List<String> deviceSerialNumbers = lines
          .map((line) => line.trim()) // Trim each line
          .where((line) => line.isNotEmpty) // Exclude empty lines
          .toList();

      // Submit emails if the list is not empty
      if (deviceSerialNumbers.isNotEmpty) {
        await _submitDeviceSerialNumbers(deviceSerialNumbers);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add New Device'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  const Text(
                    'Add a new device to this organization',
                  ),
                  TextField(
                    controller: _deviceSerialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Device Serial Number',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmitSingleEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.add),
          label: const Text('Add Device'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onCsvFileSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.upload_file),
          label: const Text('Add Devices from CSV'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () async {
            await downloadCSV();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Download CSV Template'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
        ),
      ],
    );
  }
}
