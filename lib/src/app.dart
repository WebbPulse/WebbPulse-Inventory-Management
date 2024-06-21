import 'package:flutter/material.dart';

import 'providers/settingsProvider.dart';
import 'providers/authenticationProvider.dart';
import 'providers/organizationsProvider.dart';

import 'services/firestoreService.dart';

import 'views/home_view.dart';
import 'views/settings_view.dart';
import 'views/sign_in/signin_view.dart';
import 'views/sign_in/forgot_password_view.dart';
import 'views/profile_view.dart';
import 'views/devices_view.dart';
import 'views/checkout_view.dart';
import 'views/users_view.dart';
import 'views/sign_in/landing_view.dart';
import 'views/sign_in/create_organization_view.dart';
import 'views/sign_in/register_view.dart';

class App extends StatelessWidget {
  final AuthenticationProvider authProvider;
  final SettingsProvider settingsProvider;
  final FirestoreService firestoreService;
  final OrganizationsProvider orgProvider;

  App(
      {Key? key,
      required this.settingsProvider,
      required this.authProvider,
      required this.firestoreService,
      required this.orgProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'app',
      title: 'WebbPulse Checkout',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: settingsProvider.themeMode,
      onGenerateRoute: (RouteSettings routeSettings) {
        if (!authProvider.loggedIn &&
            routeSettings.name != LandingScreen.routeName &&
            routeSettings.name != SignInView.routeName &&
            routeSettings.name != ForgotPasswordPage.routeName &&
            routeSettings.name != RegisterPage.routeName) {
          return MaterialPageRoute<void>(
            builder: (context) => LandingScreen(),
          );
        }

        print('orgs: ${orgProvider.organizationUids}');

        if (authProvider.loggedIn &&
            orgProvider.organizationUids.isEmpty &&
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
  }
}
