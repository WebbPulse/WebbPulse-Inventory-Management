import 'package:flutter/material.dart';

import 'providers/settingsProvider.dart';

import 'services/firestoreService.dart';


import 'views/sign_in/signin_view.dart';
import 'views/sign_in/forgot_password_view.dart';
import 'views/sign_in/landing_view.dart';
import 'views/sign_in/register_view.dart';

class NonAuthedApp extends StatelessWidget {
  
  final SettingsProvider settingsProvider;
  final FirestoreService firestoreService;
  

  NonAuthedApp(
      {Key? key,
      required this.settingsProvider,
      required this.firestoreService,
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
  
    return MaterialApp(
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
                builder: (context) => LandingScreen(),
              );
          }
        });
  }
}
    
    
