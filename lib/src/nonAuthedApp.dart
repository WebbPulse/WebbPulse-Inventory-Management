import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settingsProvider.dart';

import 'services/firestoreService.dart';

import 'views/nonAuthed/signin_view.dart';
import 'views/nonAuthed/forgot_password_view.dart';
import 'views/nonAuthed/landing_view.dart';
import 'views/nonAuthed/register_view.dart';

class NonAuthedApp extends StatelessWidget {
  final FirestoreService firestoreService;

  NonAuthedApp({
    Key? key,
    required this.firestoreService,
  }) : super(key: key);

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
              case ForgotPasswordPage.routeName:
                return MaterialPageRoute<void>(
                  builder: (context) => ForgotPasswordPage(),
                );
              default:
                return MaterialPageRoute<void>(
                  builder: (context) => LandingView(),
                );
            }
          }),
    );
  }
}
