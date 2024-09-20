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

class AuthedApp extends StatelessWidget {
  AuthedApp({
    super.key,
  });
  final AsyncContextHelpers snackBarHelpers = AsyncContextHelpers();
  final FirestoreReadService firestoreService = FirestoreReadService();
  final FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;
  late final DeviceCheckoutService deviceCheckoutService =
      DeviceCheckoutService(
          firestoreService: firestoreService,
          firebaseFunctions: firebaseFunctions);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgSelectorChangeNotifier>(
            create: (_) => OrgSelectorChangeNotifier()),
        ChangeNotifierProvider<OrgMemberSelectorChangeNotifier>(
            create: (_) => OrgMemberSelectorChangeNotifier()),
        Provider<FirestoreReadService>(create: (_) => firestoreService),
        Provider<FirebaseFunctions>.value(value: firebaseFunctions),
        Provider<DeviceCheckoutService>(create: (_) => deviceCheckoutService),
      ],
      child: Consumer5<
          OrgSelectorChangeNotifier,
          SettingsChangeNotifier,
          AuthenticationChangeNotifier,
          OrgMemberSelectorChangeNotifier,
          FirestoreReadService>(
        builder: (context, orgSelectorProvider, settingsProvider, authProvider,
            orgMemberSelectorProvider, firestoreReadService, child) {
          return StreamBuilder<bool>(
              stream: firestoreReadService
                  .doesGlobalUserExistInFirestore(authProvider.user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const CircularProgressIndicator();
                } else if (snapshot.data == false) {
                  firebaseFunctions
                      .httpsCallable('create_global_user_profile_callable')
                      .call({});
                  return const CircularProgressIndicator();
                }

                return MaterialApp(
                  restorationScopeId: 'authedapp',
                  title: 'WebbPulse Inventory Management',
                  theme: ThemeData(),
                  darkTheme: ThemeData.dark(),
                  themeMode: settingsProvider.themeMode,
                  onGenerateRoute: (RouteSettings routeSettings) {
                    if (authProvider.user!.emailVerified == false) {
                      return MaterialPageRoute<void>(
                        builder: (context) => const VerifyEmailView(),
                      );
                    }

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

                    if (orgSelectorProvider.orgId.isEmpty) {
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgSelectionView(),
                      );
                    }

                    if (orgMemberSelectorProvider.orgMemberId.isNotEmpty) {
                      return MaterialPageRoute<void>(
                        builder: (context) => const OrgMemberView(),
                      );
                    }

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
                        return MaterialPageRoute<void>(
                          builder: (context) => const DeviceCheckoutView(),
                        );
                    }
                  },
                );
              });
        },
      ),
    );
  }
}
