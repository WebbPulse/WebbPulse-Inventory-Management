import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/shared/providers/authenticationProvider.dart';
import 'src/shared/providers/settingsProvider.dart';

import 'src/apps/authed/authedApp.dart';
import 'src/apps/nonAuthed/nonAuthedApp.dart';

import 'src/shared/services/firestoreService.dart';
import 'src/shared/services/settingsService.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider(SettingsService());
  await settingsProvider.loadSettings();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirestoreService firestoreService = FirestoreService();

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>(
          create: (_) => AuthenticationProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
      ],
      child: Consumer<AuthenticationProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.loggedIn) {
            return AuthedApp(
              firestoreService: firestoreService,
            );
          } else {
            return NonAuthedApp(
              firestoreService: firestoreService,
            );
          }
        },
      )));
}
