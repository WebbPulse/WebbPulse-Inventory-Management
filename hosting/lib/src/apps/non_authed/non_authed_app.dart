import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/settings_change_notifier.dart';
import 'views/user_session_expired_view.dart';
import 'views/landing_view.dart';
import 'views/register_view.dart';
import 'views/signin_view.dart';
import 'views/forgot_password_view.dart';

/// Main app widget for non-authenticated users
/// Handles routing for login, registration, password reset, and session expiration views
class NonAuthedApp extends StatelessWidget {
  const NonAuthedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer2 listens to both AuthenticationChangeNotifier and SettingsChangeNotifier
    return Consumer2<AuthenticationChangeNotifier, SettingsChangeNotifier>(
      builder:
          (context, authenticationChangeNotifier, settingsProvider, child) =>
              MaterialApp(
        restorationScopeId:
            'nonauthedapp', // Enable state restoration for the app
        title: 'WebbPulse Inventory Management', // App title
        theme: ThemeData(), // Light theme
        darkTheme: ThemeData.dark(), // Dark theme
        themeMode:
            settingsProvider.themeMode, // Use theme mode from settings provider
        // Define routing logic for different views
        onGenerateRoute: (RouteSettings routeSettings) {
          // Check if the user session has expired
          if (authenticationChangeNotifier.userWasLoggedIn == true) {
            // Redirect to UserSessionExpiredView if the user was logged in but their session expired
            return MaterialPageRoute<void>(
              builder: (context) => const UserSessionExpiredView(),
            );
          }

          // Handle different routes based on route name
          switch (routeSettings.name) {
            // Route for the registration view
            case RegisterView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const RegisterView(),
              );
            // Route for the sign-in view
            case SignInView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const SignInView(),
              );
            // Route for the forgot password view
            case ForgotPasswordView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const ForgotPasswordView(),
              );
            // Default route (Landing view)
            default:
              return MaterialPageRoute<void>(
                builder: (context) => const LandingView(),
              );
          }
        },
      ),
    );
  }
}
