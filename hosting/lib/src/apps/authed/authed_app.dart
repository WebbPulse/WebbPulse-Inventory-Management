import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../shared/providers/authentication_change_notifier.dart';

import '../../shared/providers/settings_change_notifier.dart';
import '../../shared/providers/org_selector_change_notifier.dart';
import '../../shared/providers/org_member_selector_change_notifier.dart';

import '../../shared/providers/firestore_read_service.dart';
import '../../shared/providers/device_checkout_service.dart';
import '../../shared/helpers/async_context_helpers.dart';

import 'views/org_selection_view.dart';

import 'views/user_settings_view.dart';
import 'views/profile_settings_view.dart';
import 'views/org_device_list_view.dart';
import 'views/device_checkout_view.dart';
import 'views/org_member_list_view.dart';
import 'views/org_create_view.dart';
import 'views/org_member_view.dart';

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
      child: Consumer4<OrgSelectorChangeNotifier, SettingsChangeNotifier,
          AuthenticationChangeNotifier, OrgMemberSelectorChangeNotifier>(
        builder: (context, orgSelectorProvider, settingsProvider, authProvider,
            orgMemberSelectorProvider, child) {
          return MaterialApp(
            restorationScopeId: 'authedapp',
            title: 'WebbPulse Inventory Management',
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsProvider.themeMode,
            onGenerateRoute: (RouteSettings routeSettings) {
              if (routeSettings.name == OrgCreateView.routeName) {
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
                case UserSettingsView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const UserSettingsView(),
                  );
                case ProfileSettingsView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const ProfileSettingsView(),
                  );
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
                default:
                  return MaterialPageRoute<void>(
                    builder: (context) => const DeviceCheckoutView(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
