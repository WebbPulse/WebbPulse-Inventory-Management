import 'package:flutter/material.dart';

import 'providers/settingsProvider.dart';
import 'providers/authenticationProvider.dart';

import 'services/firestoreService.dart';

import 'views/home_view.dart';
import 'views/settings_view.dart';
import 'views/sign_in/signin_view.dart';
import 'views/profile_view.dart';
import 'views/devices_view.dart';
import 'views/checkout_view.dart';
import 'views/users_view.dart';
import 'views/sign_in/create_organization_view.dart';
import 'views/sign_in/register_view.dart';

class AuthedApp extends StatelessWidget {
  final AuthenticationProvider authProvider;
  final SettingsProvider settingsProvider;
  final FirestoreService firestoreService;

  AuthedApp({
    Key? key,
    required this.settingsProvider,
    required this.authProvider,
    required this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
        future: firestoreService.getOrganizations(authProvider.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error loading organizations');
          }
          List organizationUids = snapshot.data ?? [];
          return MaterialApp(
            restorationScopeId: 'app',
            title: 'WebbPulse Checkout',
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsProvider.themeMode,
            onGenerateRoute: (RouteSettings routeSettings) {
              print('orgs: $organizationUids');

              if (organizationUids.isEmpty &&
                  routeSettings.name != CreateOrganizationScreen.routeName) {
                return MaterialPageRoute<void>(
                  builder: (context) => CreateOrganizationScreen(
                    firestoreService: firestoreService,
                    uid: authProvider.uid,
                  ),
                );
              }

              switch (routeSettings.name) {
                case HomeScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  );
                case SettingsScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) =>
                        SettingsScreen(settingsProvider: settingsProvider),
                  );
                case ProfilePage.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const ProfilePage(),
                  );
                case DevicesScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const DevicesScreen(),
                  );
                case CheckoutScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const CheckoutScreen(),
                  );
                case UsersScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const UsersScreen(),
                  );
                case RegisterPage.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => RegisterPage(),
                  );
                case SignInView.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => SignInView(
                      firestoreService: firestoreService,
                    ),
                  );
                default:
                  return MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  );
              }
            },
          );
        });
  }
}
