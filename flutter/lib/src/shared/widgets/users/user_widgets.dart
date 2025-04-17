import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/org_selector_change_notifier.dart';
import '../../providers/authentication_change_notifier.dart';

import '../../../apps/authed/views/org_selection_view.dart';
import '../../../apps/authed/views/profile_settings_view.dart';
import '../../../apps/authed/views/org_selected/org_device_list_view.dart';
import '../../../apps/authed/views/org_selected/org_member_list_view.dart';
import '../../../apps/authed/views/org_selected/org_settings_view.dart';

/// Widget for displaying the user's profile avatar
/// It handles both valid and invalid photo URLs, showing a default icon on error
class ProfileAvatar extends StatefulWidget {
  final String? photoUrl; // The URL of the user's profile photo

  const ProfileAvatar({super.key, this.photoUrl});

  @override
  ProfileAvatarState createState() => ProfileAvatarState();
}

class ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasError = false; // Tracks whether there was an error loading the image

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 75, // Set the size of the avatar
      backgroundColor: _hasError
          ? Theme.of(context)
              .colorScheme
              .onSecondary // Error color if image fails to load
          : null, // Default color if no error
      backgroundImage: !_hasError && widget.photoUrl != null
          ? NetworkImage(widget.photoUrl!) // Load image from URL
          : null, // No image if there's an error or no URL
      onBackgroundImageError: !_hasError
          ? (exception, stackTrace) {
              // Set error state if image loading fails
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true; // Set error flag to true
                  });
                }
              });
            }
          : null, // Do nothing if there's already an error
      child: _hasError
          ? Icon(
              Icons.person, // Display default person icon on error
              size: 50,
              color: Theme.of(context).colorScheme.secondary,
            )
          : null, // No child if there's no error
    );
  }
}

/// Widget for checking user's authentication claims (e.g., admin or desk station roles)
/// It builds different UIs based on the user's claims
class AuthClaimChecker extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, dynamic> claims)
      builder;

  const AuthClaimChecker({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationChangeNotifier>(
      builder: (context, authenticationChangeNotifier, child) {
        final user = authenticationChangeNotifier.user; // Get the current user

        if (user == null) {
          return const Center(
              child: Text(
                  'User not signed in')); // Show message if no user is signed in
        }

        // Fetch the user's ID token to retrieve their claims
        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(), // Get ID token result
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator()); // Show loading indicator while waiting
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text(
                      'Error loading user data')); // Show error message on failure
            } else if (!snapshot.hasData) {
              return const Center(
                  child: Text(
                      'No token data available')); // Show message if no token data
            }

            final claims =
                snapshot.data!.claims; // Get user claims from the token

            return builder(context, claims!); // Build the UI using the claims
          },
        );
      },
    );
  }
}

/// Drawer widget for authenticated users
/// Provides menu options based on the user's organization and role
class AuthedDrawer extends StatelessWidget {
  const AuthedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthClaimChecker(builder: (context, userClaims) {
      final orgId = Provider.of<OrgSelectorChangeNotifier>(context)
          .orgId; // Get the current organization ID
      final authenticationChangeNotifier =
          Provider.of<AuthenticationChangeNotifier>(
              context); // Get the authentication provider

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero, // No padding for the drawer
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).primaryColor, // Header background color
              ),
              child: const Text('Menu'), // Header text
            ),
            // Display organization-specific menu options if an organization is selected
            if (orgId.isNotEmpty) ...[
              if (userClaims['org_admin_$orgId'] ==
                  true) // Show organization settings for admins
                ListTile(
                  leading: const Icon(Icons.settings), // Settings icon
                  title: const Text('Organization Settings'), // Label
                  onTap: () {
                    Navigator.pushNamed(
                        context,
                        OrgSettingsView
                            .routeName); // Navigate to OrgSettingsView
                  },
                ),
              ListTile(
                leading: const Icon(Icons.devices), // Devices icon
                title: const Text('Devices'), // Label
                onTap: () {
                  Navigator.pushNamed(
                      context,
                      OrgDeviceListView
                          .routeName); // Navigate to OrgDeviceListView
                },
              ),
              ListTile(
                leading: const Icon(Icons.people), // Users icon
                title: const Text('Users'), // Label
                onTap: () {
                  Navigator.pushNamed(
                      context,
                      OrgMemberListView
                          .routeName); // Navigate to OrgMemberListView
                },
              ),
            ],
            // Show profile settings unless the user is on a desk station
            if (userClaims['org_deskstation_$orgId'] != true)
              ListTile(
                leading: const Icon(Icons.person), // Profile icon
                title: const Text('Profile'), // Label
                onTap: () {
                  Navigator.pushNamed(
                      context,
                      ProfileSettingsView
                          .routeName); // Navigate to ProfileSettingsView
                },
              ),
            ListTile(
              leading: const Icon(Icons.home), // Home icon
              title: const Text('My Organizations'), // Label
              onTap: () {
                Navigator.pushNamed(context,
                    OrgSelectionView.routeName); // Navigate to OrgSelectionView
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout), // Logout icon
              title: const Text('Sign Out'), // Label
              onTap: () {
                authenticationChangeNotifier.signOutUser(); // Sign out the user
              },
            ),
          ],
        ),
      );
    });
  }
}
