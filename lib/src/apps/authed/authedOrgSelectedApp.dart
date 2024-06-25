import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/authenticationProvider.dart';
import '../../providers/settingsProvider.dart';
import '../../providers/orgSelectorProvider.dart';

import '../../services/firestoreService.dart';

import '../../views/authed/org_selection_view.dart';
import '../../views/authed/home_view.dart';
import '../../views/authed/settings_view.dart';
import '../../views/authed/profile_view.dart';
import '../../views/authed/devices_view.dart';
import '../../views/authed/checkout_view.dart';
import '../../views/authed/users_view.dart';
import '../../views/authed/create_organization_view.dart';

class AuthedOrgSelectedApp extends StatelessWidget {
  final FirestoreService firestoreService;
  final List<String> organizationUids;

  AuthedOrgSelectedApp({
    Key? key,
    required this.firestoreService,
    required this.organizationUids,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthenticationProvider, OrgSelectorProvider,
        SettingsProvider>(
      builder: (context, authProvider, orgSelectorProvider, settingsProvider,
          child) {
        return MaterialApp(
          restorationScopeId: 'app',
          title: 'WebbPulse Checkout',
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsProvider.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            print('selected org: ${orgSelectorProvider.selectedOrg}');

            if (routeSettings.name == CreateOrganizationView.routeName) {
              return MaterialPageRoute<void>(
                builder: (context) => CreateOrganizationView(
                  firestoreService: firestoreService,
                  uid: authProvider.uid,
                ),
              );
            }

            if (orgSelectorProvider.selectedOrg.isEmpty) {
              return MaterialPageRoute<void>(
                builder: (context) => OrgSelectionView(
                    organizationUids: organizationUids,
                    orgSelectorProvider: orgSelectorProvider),
              );
            }

            switch (routeSettings.name) {
              case HomeView.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const HomeView(),
                );
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
                  builder: (context) => const DevicesView(),
                );
              case CheckoutView.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const CheckoutView(),
                );
              case UsersView.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const UsersView(),
                );
              case OrgSelectionView.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => OrgSelectionView(
                      organizationUids: organizationUids,
                      orgSelectorProvider: orgSelectorProvider),
                );
              default:
                return MaterialPageRoute<void>(
                  builder: (context) => const HomeView(),
                );
            }
          },
        );
      },
    );
  }
}
