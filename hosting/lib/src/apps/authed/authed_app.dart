import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/settings_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/org_member_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';
import 'package:webbcheck/src/shared/providers/device_checkout_service.dart';

import 'views/profile_settings_view.dart';
import 'views/org_selected/org_device_list_view.dart';
import 'views/org_selected/device_checkout_view.dart';
import 'views/org_selected/org_member_list_view.dart';
import 'views/org_selected/org_member_view.dart';
import 'package:webbcheck/src/apps/authed/views/org_selected/org_settings_view.dart';
import 'views/org_create_view.dart';
import 'views/org_selection_view.dart';
import 'views/verify_email_view.dart';

import 'package:webbcheck/src/shared/widgets/widgets.dart';

/// Main app widget for authenticated users
/// Provides routes and handles various services like Firestore and Cloud Functions
class AuthedApp extends StatelessWidget {
  AuthedApp({super.key});

  // Initialize helpers and services used throughout the app
  final AsyncContextHelpers snackBarHelpers = AsyncContextHelpers();
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
                  // Redirect to VerifyEmailView if user's email is not verified
                  if (authProvider.user!.emailVerified == false) {
                    return MaterialPageRoute<void>(
                      builder: (context) => const VerifyEmailView(),
                    );
                  }

                  // Define route handling for different views
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
                  if (orgSelectorProvider.orgId.isEmpty) {
                    return MaterialPageRoute<void>(
                      builder: (context) => const OrgSelectionView(),
                    );
                  }

                  // If a specific organization member is selected, show the OrgMemberView
                  if (orgMemberSelectorProvider.orgMemberId.isNotEmpty) {
                    return MaterialPageRoute<void>(
                      builder: (context) => const OrgMemberView(),
                    );
                  }

                  // Handle routes for organization-specific views
                  switch (routeSettings.name) {
                    case OrgDeviceListView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgDeviceListView(),
                      );
                    case DeviceCheckoutView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const DeviceCheckoutView(),
                      );
                    case OrgMemberListView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => OrgMemberListView(),
                      );
                    case OrgSelectionView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgSelectionView(),
                      );
                    case OrgMemberView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgMemberView(),
                      );
                    case OrgSettingsView.routeName:
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgSettingsView(),
                      );
                    default:
                      // Default route if no match is found
                      return MaterialPageRoute<void>(
                        builder: (context) => const DeviceCheckoutView(),
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
