import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'settings/settings_controller.dart';

import 'pages/settings_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/profile_page.dart';

///import unfinished pages with blank scaffolds
import 'pages/devices_page.dart';
import 'pages/checkout_page.dart';
import 'pages/users_page.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          title: 'WebbPulse Checkout',
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,
          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            switch (routeSettings.name) {
              case HomePage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const HomePage(),
                );
              case SettingsPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) =>
                      SettingsPage(controller: settingsController),
                );
              case SignInPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const SignInPage(),
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
              case DevicesPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const DevicesPage(),
                );
              case CheckoutPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const CheckoutPage(),
                );
              case UsersPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => const UsersPage(),
                );
              ///Default to the home page
              default:
                return MaterialPageRoute<void>(
                  builder: (context) => const HomePage(),
                );
            }
          },
        );
      },
    );
  }
}
