import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/shared/providers/authentication_change_notifier.dart';
import 'src/shared/providers/settings_change_notifier.dart';

import 'src/apps/authed/authed_app.dart';
import 'src/apps/non_authed/non_authed_app.dart';

import 'src/shared/non_provider_services/settings_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsChangeNotifier = SettingsChangeNotifier(SettingsService());
  await settingsChangeNotifier.loadSettings();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationChangeNotifier>(
          create: (_) => AuthenticationChangeNotifier(),
        ),
        ChangeNotifierProvider<SettingsChangeNotifier>.value(
          value: settingsChangeNotifier,
        ),
      ],
      child: Consumer<AuthenticationChangeNotifier>(
        builder: (context, authProvider, child) {
          if (authProvider.userLoggedIn) {
            /// If the user is logged in, show the AuthedApp
            return AuthedApp();
          } else {
            /// If the user is not logged in, show the NonAuthedApp
            return const NonAuthedApp();
          }
        },
      )));
}