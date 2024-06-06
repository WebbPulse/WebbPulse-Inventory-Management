import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/authentication_state.dart';
import 'providers/settings_controller.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in/signin_screen_temp.dart';
import 'screens/sign_in/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/users_screen.dart';
import 'screens/sign_in/landing_screen.dart';
import 'screens/sign_in/register_screen.dart';

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
        ChangeNotifierProvider<SettingsController>.value(
          value: settingsController,
        ),
      ],
      child: Consumer2<AuthenticationState, SettingsController>(
        builder: (context, appState, settingsController, child) {
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
              if (!appState.loggedIn &&
                routeSettings.name != LandingScreen.routeName &&
                routeSettings.name != SignInPage.routeName &&
                routeSettings.name != ForgotPasswordPage.routeName &&
                routeSettings.name != RegisterScreen.routeName) {
                // Redirect to SignInPage if not authenticated
                return MaterialPageRoute<void>(
                  builder: (context) => LandingScreen(),
                );
              }

              // Handle other routes based on routeSettings.name
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
                case RegisterScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (context) => const RegisterScreen(),
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