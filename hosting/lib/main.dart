import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/shared/providers/authenticationChangeNotifier.dart';
import 'src/shared/providers/settingsChangeNotifier.dart';

import 'src/apps/authed/authedApp.dart';
import 'src/apps/nonAuthed/nonAuthedApp.dart';

import 'src/shared/services/settingsService.dart';
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
