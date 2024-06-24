import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/providers/authenticationProvider.dart';
import 'src/providers/settingsProvider.dart';

import 'src/authedApp.dart';
import 'src/nonAuthedApp.dart';

import 'src/services/firestoreService.dart';
import 'src/services/settingsService.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider(SettingsService());
  await settingsProvider.loadSettings();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirestoreService firestoreService = FirestoreService();

  runApp(MyApp(
    firestoreService: firestoreService,
    settingsProvider: settingsProvider,
  ));
}

class MyApp extends StatelessWidget {
  final FirestoreService firestoreService;
  final SettingsProvider settingsProvider;

  MyApp({required this.firestoreService, required this.settingsProvider});

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
      child: Consumer2<AuthenticationProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, child) {
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
      ),
    );
  }
}
