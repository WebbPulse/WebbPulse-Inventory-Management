import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settingsProvider.dart';

import '../services/firestoreService.dart';

import '../views/nonAuthed/signin_view.dart';
import '../views/nonAuthed/forgot_password_view.dart';
import '../views/nonAuthed/landing_view.dart';
import '../views/nonAuthed/register_view.dart';

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
          restorationScopeId: 'app',
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
                  builder: (context) => SignInView(
                    firestoreService: firestoreService,
                  ),
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
          }),
    );
  }
}
