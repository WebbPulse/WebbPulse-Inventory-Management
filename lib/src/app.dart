import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_checkout/src/screens/sign_in/register_screen.dart';

import 'services/providers/authentication_service.dart';
import 'services/providers/settings_controller.dart';
import 'services/providers/firestore_service.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in/signin_screen_temp.dart';
import 'screens/sign_in/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/users_screen.dart';
import 'screens/sign_in/landing_screen.dart';
import 'screens/sign_in/create_organization_screen.dart';


class App extends StatelessWidget {
  const App({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationState>(
          create: (_) => AuthenticationState(), 
        ),
        ChangeNotifierProxyProvider<AuthenticationState, FirestoreService>(
          create: (_) => FirestoreService(),
          update: (_, authState, firestoreService)  {
            if (authState.authUid != firestoreService?.uid) {
              firestoreService?.handleAuthStateChange(authState.authUid);
            }
            return firestoreService!;
          },
        ),
        ChangeNotifierProvider<SettingsController>.value(
          value: settingsController,
        ),
      ],
      child: Consumer3<AuthenticationState, SettingsController, FirestoreService>(
        builder: (context, authState, settingsController, firestoreService, child) {
          return MaterialApp(
            restorationScopeId: 'app',
            title: 'WebbPulse Checkout',
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: settingsController.themeMode,
            // Define a function to handle named routes in order to support
            // Flutter web url navigation and deep linking.
            onGenerateRoute: (RouteSettings routeSettings) {
              // Check if the user is signed in
              if (!authState.loggedIn &&
                routeSettings.name != LandingScreen.routeName &&
                routeSettings.name != SignInPage.routeName &&
                routeSettings.name != ForgotPasswordPage.routeName &&
                routeSettings.name != CreateOrganizationScreen.routeName &&
                routeSettings.name != RegisterPage.routeName) {
                // Redirect to LandingPage if not authenticated
                return MaterialPageRoute<void>(
                  builder: (context) => LandingScreen(),
                );
              }

              if (authState.loggedIn && firestoreService.organizationUids.isEmpty && routeSettings.name != CreateOrganizationScreen.routeName) {
                // Redirect to CreateOrganizationScreen if user has no organizations
                return MaterialPageRoute<void>(
                  builder: (context) => ProfileScreen(),
                );
              }

              switch (routeSettings.name) {
                case HomeScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  );
                case SettingsScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => SettingsScreen(controller: settingsController),
                  );
                case SignInPage.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => SignInPage(),
                  );
                case ForgotPasswordPage.routeName:
                  final String? email = routeSettings.arguments as String?;
                  return MaterialPageRoute<void>(
                    builder: (context) => ForgotPasswordPage(email: email ?? ''),
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
                case LandingScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => LandingScreen(),
                  );
                case RegisterPage.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => RegisterPage(),
                  );
                case CreateOrganizationScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => CreateOrganizationScreen(),
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