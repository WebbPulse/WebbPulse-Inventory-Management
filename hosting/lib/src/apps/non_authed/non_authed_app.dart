import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';

import '../../shared/providers/settings_change_notifier.dart';
import 'views/user_session_expired_view.dart';
import 'views/landing_view.dart';
import 'views/register_view.dart';
import 'views/signin_view.dart';
import 'views/forgot_password_view.dart';

class NonAuthedApp extends StatelessWidget {
  const NonAuthedApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthenticationChangeNotifier, SettingsChangeNotifier>(
      builder:
          (context, authenticationChangeNotifier, settingsProvider, child) =>
              MaterialApp(
        restorationScopeId: 'nonauthedapp',
        title: 'WebbPulse Inventory Management',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: settingsProvider.themeMode,
        onGenerateRoute: (RouteSettings routeSettings) {
          if (authenticationChangeNotifier.userWasLoggedIn == true) {
            return MaterialPageRoute<void>(
              builder: (context) => const UserSessionExpiredView(),
            );
          }
          switch (routeSettings.name) {
            case RegisterView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const RegisterView(),
              );
            case SignInView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const SignInView(),
              );
            case ForgotPasswordView.routeName:
              return MaterialPageRoute<void>(
                builder: (context) => const ForgotPasswordView(),
              );
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
