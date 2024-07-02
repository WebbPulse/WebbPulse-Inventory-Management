import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/settingsProvider.dart';
import '../../shared/providers/orgSelectorProvider.dart';

import '../../shared/services/firestoreService.dart';
import '../../shared/services/deviceCheckoutService.dart';

import 'views/org_selection_view.dart';

import 'views/settings_view.dart';
import 'views/profile_view.dart';
import 'views/devices_view.dart';
import 'views/checkout_view.dart';
import 'views/users_view.dart';
import 'views/create_organization_view.dart';

class AuthedUserExistsApp extends StatelessWidget {
  AuthedUserExistsApp({
    super.key,
    required this.firestoreService,
  });
  final FirestoreService firestoreService;
  late final DeviceCheckoutService deviceCheckoutService =
      DeviceCheckoutService(firestoreService: firestoreService);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrgSelectorProvider(),
      child: Consumer2<OrgSelectorProvider, SettingsProvider>(
        builder: (context, orgSelectorProvider, settingsProvider, child) {
          return MaterialApp(
            restorationScopeId: 'authedapp',
            title: 'WebbPulse Checkout',
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsProvider.themeMode,
            onGenerateRoute: (RouteSettings routeSettings) {
              if (routeSettings.name == CreateOrganizationView.routeName) {
                return MaterialPageRoute<void>(
                  builder: (context) => CreateOrganizationView(
                    firestoreService: firestoreService,
                  ),
                );
              }

              if (orgSelectorProvider.selectedOrgUid.isEmpty) {
                return MaterialPageRoute<void>(
                  builder: (context) => OrgSelectionView(
                    firestoreService: firestoreService,
                  ),
                );
              }

              switch (routeSettings.name) {
                case SettingsView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) =>
                        SettingsView(settingsProvider: settingsProvider),
                  );
                case ProfileView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const ProfileView(),
                  );
                case DevicesView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => DevicesView(
                      firestoreService: firestoreService,
                      deviceCheckoutService: deviceCheckoutService,
                    ),
                  );
                case CheckoutView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => CheckoutView(
                        firestoreService: firestoreService,
                        deviceCheckoutService: deviceCheckoutService),
                  );
                case UsersView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => UsersView(
                      firestoreService: firestoreService,
                    ),
                  );
                case OrgSelectionView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => OrgSelectionView(
                      firestoreService: firestoreService,
                    ),
                  );
                default:
                  return MaterialPageRoute<void>(
                    builder: (context) => CheckoutView(
                        firestoreService: firestoreService,
                        deviceCheckoutService: deviceCheckoutService),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
