import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/settings_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_member_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/device_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/device_checkout_service.dart';

import 'views/profile_settings_view.dart';
import 'views/org_selected/org_device_list_view.dart';
import 'views/org_selected/org_member_list_view.dart';
import 'views/org_selected/org_member_view.dart';
import 'views/org_selected/device_checkout_note_view.dart';
import 'package:webbpulse_inventory_management/src/apps/authed/views/org_selected/org_settings_view.dart';
import 'views/org_create_view.dart';
import 'views/org_selection_view.dart';
import 'views/verify_email_view.dart';
import 'views/email_not_verified_view.dart';
import 'views/configure_password.dart';

import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';

/// Main app widget for authenticated users
/// Provides routes and handles various services like Firestore and Cloud Functions
class AuthedApp extends StatelessWidget {
  AuthedApp({super.key});

  // Initialize helpers and services used throughout the app
  final AsyncContextHelpers asyncContextHelpers = AsyncContextHelpers();
  final FirestoreReadService firestoreService = FirestoreReadService();
  final FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;

  // Initialize DeviceCheckoutService with dependencies
  late final DeviceCheckoutService deviceCheckoutService =
      DeviceCheckoutService(
          firestoreService: firestoreService,
          firebaseFunctions: firebaseFunctions);

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to supply multiple providers to the widget tree
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgSelectorChangeNotifier>(
            create: (_) =>
                OrgSelectorChangeNotifier()), // Manages organization selection
        ChangeNotifierProvider<OrgMemberSelectorChangeNotifier>(
            create: (_) =>
                OrgMemberSelectorChangeNotifier()), // Manages organization member selection
        ChangeNotifierProvider<DeviceSelectorChangeNotifier>(
            create: (_) =>
                DeviceSelectorChangeNotifier()), // Manages user settings
        Provider<FirestoreReadService>(
            create: (_) => firestoreService), // Provides Firestore read service
        Provider<FirebaseFunctions>.value(
            value: firebaseFunctions), // Provides Firebase functions
        Provider<DeviceCheckoutService>(
            create: (_) =>
                deviceCheckoutService), // Provides DeviceCheckoutService
      ],
      child: Consumer5<
          OrgSelectorChangeNotifier,
          SettingsChangeNotifier,
          AuthenticationChangeNotifier,
          OrgMemberSelectorChangeNotifier,
          FirestoreReadService>(
        builder: (context, orgSelectorProvider, settingsProvider, authProvider,
            orgMemberSelectorProvider, firestoreReadService, child) {
          // Use StreamBuilder to check if the global user exists in Firestore
          return StreamBuilder<bool>(
            stream: firestoreReadService
                .doesGlobalUserExistInFirestore(authProvider.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Show loading indicator while waiting for data
              } else if (snapshot.hasError) {
                return const CircularProgressIndicator(); // Show error state (could improve error handling)
              } else if (snapshot.data == false) {
                // If the user doesn't exist, call Firebase Function to create the global user profile
                firebaseFunctions
                    .httpsCallable('create_global_user_profile_callable')
                    .call({});
                return const CircularProgressIndicator(); // Show loading indicator while creating profile
              }

              // Build the MaterialApp for authenticated users
              return MaterialApp(
                restorationScopeId:
                    'authedapp', // Enable state restoration for the app
                title: 'WebbPulse Inventory Management', // App title
                theme: ThemeData(), // Light theme
                darkTheme: ThemeData.dark(), // Dark theme
                themeMode: settingsProvider
                    .themeMode, // Set theme mode based on user settings
                // Define route generation logic
                onGenerateRoute: (RouteSettings routeSettings) {
                  // Handle routes for first time account setup views
                  if (authProvider.noPasswordConfigured == true ||
                      routeSettings.name == ConfigurePasswordView.routeName) {
                    return MaterialPageRoute<void>(
                      builder: (context) => const ConfigurePasswordView(),
                    );
                  }
                  if (authProvider.userEmailVerified == false) {
                    if (routeSettings.name == VerifyEmailView.routeName) {
                      return MaterialPageRoute<void>(
                        builder: (context) => const VerifyEmailView(),
                      );
                    } else {
                      return MaterialPageRoute<void>(
                        builder: (context) => const EmailNotVerifiedView(),
                      );
                    }
                  }

                  // Define route handling for non-organization-specific views
                  switch (routeSettings.name) {
                    case ProfileSettingsView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const ProfileSettingsView(),
                      );
                    case OrgCreateView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgCreateView(),
                      );
                  }

                  // If no organization is selected, show the OrgSelectionView
                  if (orgSelectorProvider.orgId.isEmpty ||
                      routeSettings.name == OrgSelectionView.routeName) {
                    return MaterialPageRoute<void>(
                      builder: (context) => const OrgSelectionView(),
                    );
                  }

                  // Provider dependant view, make sure you can only get there if you set the provider properly
                  if (orgMemberSelectorProvider.orgMemberId.isNotEmpty) {
                    return MaterialPageRoute<void>(
                      builder: (context) => OrgMemberView(),
                    );
                  }

                  // Handle routes for organization-specific views
                  switch (routeSettings.name) {
                    case OrgDeviceListView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => OrgDeviceListView(),
                      );
                    case OrgMemberListView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgMemberListView(),
                      );
                    case OrgSettingsView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgSettingsView(),
                      );
                    case DeviceCheckoutNoteView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const DeviceCheckoutNoteView(),
                      );
                    default:
                      // Default route if no match is found
                      return MaterialPageRoute<void>(
                        builder: (context) => OrgDeviceListView(),
                      );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
