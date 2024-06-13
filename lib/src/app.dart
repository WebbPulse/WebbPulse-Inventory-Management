import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/authenticationProvider.dart';
import 'providers/settingsProvider.dart';
import 'providers/firestoreProvider.dart';

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
  const App({
    Key? key,
    required this.settingsProvider,
  }) : super(key: key);

  final SettingsProvider settingsProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>(
          create: (_) => AuthenticationProvider(), 
        ),
        ChangeNotifierProxyProvider<AuthenticationProvider, FirestoreProvider>(
          create: (_) => FirestoreProvider(),
          update: (_, authProvider, firestoreProvider)  {
            if (authProvider.authUid != firestoreProvider?.uid) {
              firestoreProvider?.handleAuthStateChange(authProvider.authUid);
            }
            return firestoreProvider!;
          },
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
      ],
      child: Consumer3<AuthenticationProvider, SettingsProvider, FirestoreProvider>(
        builder: (context, authProvider, settingsProvider, firestoreProvider, child) {
          return MaterialApp(
            restorationScopeId: 'app',
            title: 'WebbPulse Checkout',
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsProvider.themeMode,
            // Define a function to handle named routes in order to support
            // Flutter web url navigation and deep linking.
            onGenerateRoute: (RouteSettings routeSettings) {
              // Check if the user is signed in
              if (!authProvider.loggedIn &&
                routeSettings.name != LandingScreen.routeName &&
                routeSettings.name != SignInView.routeName &&
                routeSettings.name != ForgotPasswordPage.routeName &&
                routeSettings.name != CreateOrganizationScreen.routeName &&
                routeSettings.name != RegisterPage.routeName) {
                // Redirect to LandingPage if not authenticated
                return MaterialPageRoute<void>(
                  builder: (context) => LandingScreen(),
                );
              }

              if (authProvider.loggedIn && firestoreProvider.organizationUids.isEmpty && routeSettings.name != CreateOrganizationScreen.routeName) {
                // Redirect to CreateOrganizationScreen if user has no organizations
                return MaterialPageRoute<void>(
                  builder: (context) => CreateOrganizationScreen(uid: firestoreProvider.uid),
                );
              }

              switch (routeSettings.name) {
                case HomeScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  );
                case SettingsScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => SettingsScreen(settingsProvider: settingsProvider),
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
                    builder: (context) => SignInView(),
                  );
                default:
                  // Default to Home Page if route not found
                  return MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}