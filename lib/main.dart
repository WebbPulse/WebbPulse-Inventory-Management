import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/providers/authenticationProvider.dart';
import 'src/providers/settingsProvider.dart';
import 'src/providers/organizationsProvider.dart'; // Ensure this import is added

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
      ChangeNotifierProvider<OrganizationsProvider>(
        create: (_) => OrganizationsProvider(),
      ),
    ],
    child: Consumer3<AuthenticationProvider, SettingsProvider, OrganizationsProvider>(
      builder: (context, authProvider, settingsProvider, orgProvider, child) {
        if (authProvider.loggedIn) {
          return AuthedApp(
            firestoreService: firestoreService,
            settingsProvider: settingsProvider,
            authProvider: authProvider,
            orgProvider: orgProvider,
          );
        }
        else if (authProvider.loggedIn == false){
          orgProvider.setOrganizations([]);
          return NonAuthedApp(
          firestoreService: firestoreService,
          settingsProvider: settingsProvider,
        );
        }
        return const CircularProgressIndicator();
      },
    ),
  ));
}
        
      
