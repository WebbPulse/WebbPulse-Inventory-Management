import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'providers/authenticationProvider.dart';
import 'providers/settingsProvider.dart';
import 'services/firestoreService.dart';

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
  App({
    Key? key,
    required this.settingsProvider,
  }) : super(key: key);

  final SettingsProvider settingsProvider;
  final firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>(
          create: (_) => AuthenticationProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
      ],
      child: Consumer<AuthenticationProvider>(
        builder: (context, authProvider, _) {
          return StreamProvider<List<String>>(
            create: (_) => authProvider.uidStream.switchMap((uid) {
              if (uid == null) {
                return Stream<List<String>>.value([]);
              }
              return firestoreService.userOrganizationsStream(uid);
            }),
            initialData: ['cake'],
            catchError: (_, error) {
              print("StreamProvider error: $error");
              return [];
            },
            child: Consumer3<AuthenticationProvider, SettingsProvider,
                List<String>>(
              builder: (context, authProvider, settingsProvider,
                  organizationUids, child) {
                return MaterialApp(
                  restorationScopeId: 'app',
                  title: 'WebbPulse Checkout',
                  theme: ThemeData(),
                  darkTheme: ThemeData.dark(),
                  themeMode: settingsProvider.themeMode,
                  onGenerateRoute: (RouteSettings routeSettings) {
                    print('Current organizationUids: $organizationUids');

                    if (!authProvider.loggedIn &&
                        routeSettings.name != LandingScreen.routeName &&
                        routeSettings.name != SignInView.routeName &&
                        routeSettings.name != ForgotPasswordPage.routeName &&
                        routeSettings.name != RegisterPage.routeName) {
                      return MaterialPageRoute<void>(
                        builder: (context) => LandingScreen(),
                      );
                    }

                    if (authProvider.loggedIn &&
                        organizationUids.isEmpty &&
                        routeSettings.name !=
                            CreateOrganizationScreen.routeName) {
                      return MaterialPageRoute<void>(
                        builder: (context) => CreateOrganizationScreen(
                          firestoreService: firestoreService,
                          uid: authProvider.uid,
                        ),
                      );
                    }

                    switch (routeSettings.name) {
                      case HomeScreen.routeName:
                        return MaterialPageRoute<void>(
                          builder: (context) => const HomeScreen(),
                        );
                      case SettingsScreen.routeName:
                        return MaterialPageRoute<void>(
                          builder: (context) => SettingsScreen(
                              settingsProvider: settingsProvider),
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
                          builder: (context) => SignInView(
                            firestoreService: firestoreService,
                          ),
                        );
                      default:
                        return MaterialPageRoute<void>(
                          builder: (context) => const HomeScreen(),
                        );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
