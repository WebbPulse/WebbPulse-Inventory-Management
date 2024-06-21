import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'src/providers/authenticationProvider.dart';
import 'src/providers/settingsProvider.dart';
import 'src/providers/organizationsProvider.dart'; // Ensure this import is added

import 'src/app.dart';

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
      ChangeNotifierProxyProvider<AuthenticationProvider,
          OrganizationsProvider>(
        create: (_) => OrganizationsProvider(),
        update: (context, authProvider, orgProvider) {
          if (orgProvider == null) {
            orgProvider = OrganizationsProvider();
          }

          if (authProvider.loggedIn) {
            // Use a local reference to orgProvider
            final OrganizationsProvider localOrgProvider = orgProvider;
            firestoreService.getOrganizations(authProvider.uid).then((orgUids) {
              localOrgProvider.setOrganizations(orgUids);
            });
          } else {
            orgProvider.setOrganizations([]);
          }

          return orgProvider;
        },
      ),
    ],
    child: Consumer3<AuthenticationProvider, SettingsProvider,
        OrganizationsProvider>(
      builder: (context, authProvider, settingsProvider, orgProvider, child) {
        return App(
          firestoreService: firestoreService,
          settingsProvider: settingsProvider,
          authProvider: authProvider,
          orgProvider: orgProvider,
        );
      },
    ),
  ));
}
