import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/settingsProvider.dart';

import '../../shared/services/firestoreService.dart';

import 'views/landing_view.dart';
import 'views/register_view.dart';
import 'views/signin_view.dart';
import 'views/forgot_password_view.dart';

class NonAuthedApp extends StatelessWidget {
  final FirestoreService firestoreService;

  const NonAuthedApp({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) => MaterialApp(
        restorationScopeId: 'nonauthedapp',
        title: 'WebbPulse Checkout',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: settingsProvider.themeMode,
        onGenerateRoute: (RouteSettings routeSettings) {
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
