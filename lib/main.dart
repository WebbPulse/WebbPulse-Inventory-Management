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

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthenticationProvider>(
        create: (_) => AuthenticationProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
      ),
    ],
    child: ParentApp(firestoreService: firestoreService),
  ));
}

class ParentApp extends StatelessWidget {
  final FirestoreService firestoreService;

  ParentApp({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthenticationProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, child) {
        if (authProvider.loggedIn) {
          return AuthedApp(
            firestoreService: firestoreService,
            settingsProvider: settingsProvider,
            authProvider: authProvider,
          );
        } else if (authProvider.loggedIn == false) {
          return NonAuthedApp(
            firestoreService: firestoreService,
            settingsProvider: settingsProvider,
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
