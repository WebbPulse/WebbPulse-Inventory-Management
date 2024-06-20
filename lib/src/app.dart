import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/authenticationProvider.dart';
import 'providers/settingsProvider.dart';

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
  final SettingsProvider settingsProvider;

  App({Key? key, required this.settingsProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>(
          create: (_) => AuthenticationProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
        ChangeNotifierProvider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      child:
          Consumer3<AuthenticationProvider, SettingsProvider, FirestoreService>(
        builder:
            (context, authProvider, settingsProvider, firestoreService, child) {
          // Check the state of the FirestoreService to decide what to show
          firestoreService.fetchOrganizations(authProvider.uid);
          if (firestoreService.isLoading) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (firestoreService.error != null) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${firestoreService.error}'),
              ),
            );
          } else {
            return MaterialApp(
              restorationScopeId: 'app',
              title: 'WebbPulse Checkout',
              theme: ThemeData(),
              darkTheme: ThemeData.dark(),
              themeMode: settingsProvider.themeMode,
              onGenerateRoute: (RouteSettings routeSettings) {
                print(firestoreService.organizationUids);
                if (!authProvider.loggedIn &&
                    routeSettings.name != LandingScreen.routeName &&
                    routeSettings.name != SignInView.routeName &&
                    routeSettings.name != ForgotPasswordPage.routeName &&
                    routeSettings.name != RegisterPage.routeName) {
                  return MaterialPageRoute<void>(
                    builder: (context) => LandingScreen(),
                  );
                }

                if (authProvider.loggedIn &&
                    firestoreService.organizationUids.isEmpty &&
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
        },
      ),
    );
  }
}
