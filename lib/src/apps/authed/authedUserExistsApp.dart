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

class AuthedUserExistsApp extends StatelessWidget {
  final FirestoreService firestoreService;

  AuthedUserExistsApp({
    Key? key,
    required this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrgSelectorProvider(),
      child: Consumer3<AuthenticationProvider, OrgSelectorProvider,
          SettingsProvider>(
        builder: (context, authProvider, orgSelectorProvider, settingsProvider,
            child) {
          return StreamBuilder<List<String>>(
              stream: firestoreService.orgsUidsStream(authProvider.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading organizations');
                }
                final organizationUids = snapshot.data ?? [];

                return MaterialApp(
                  restorationScopeId: 'app',
                  title: 'WebbPulse Checkout',
                  theme: ThemeData(),
                  darkTheme: ThemeData.dark(),
                  themeMode: settingsProvider.themeMode,
                  onGenerateRoute: (RouteSettings routeSettings) {
                    print(
                        'selected org: ${orgSelectorProvider.selectedOrgUid}');

                    if (routeSettings.name ==
                        CreateOrganizationView.routeName) {
                      return MaterialPageRoute<void>(
                        builder: (context) => CreateOrganizationView(
                          firestoreService: firestoreService,
                          uid: authProvider.uid,
                        ),
                      );
                    }

                    if (orgSelectorProvider.selectedOrgUid.isEmpty) {
                      return MaterialPageRoute<void>(
                        builder: (context) => OrgSelectionView(
                          organizationUids: organizationUids,
                          firestoreService: firestoreService,
                        ),
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
                          builder: (context) => DevicesView(
                            firestoreService: firestoreService,
                          ),
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
                            firestoreService: firestoreService,
                          ),
                        );
                      default:
                        return MaterialPageRoute<void>(
                          builder: (context) => const HomeView(),
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
