import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/org_selector_change_notifier.dart';
import '../providers/authentication_change_notifier.dart';

import '../../apps/authed/views/org_selection_view.dart';
import '../../apps/authed/views/profile_settings_view.dart';
import '../../apps/authed/views/org_selected/device_checkout_view.dart';
import '../../apps/authed/views/org_selected/org_device_list_view.dart';
import '../../apps/authed/views/org_selected/org_member_list_view.dart';
import '../../apps/authed/views/org_selected/org_settings_view.dart';



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