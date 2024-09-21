import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/shared/providers/authentication_change_notifier.dart';
import 'src/shared/providers/settings_change_notifier.dart';
import 'src/apps/authed/authed_app.dart';
import 'src/apps/non_authed/non_authed_app.dart';
import 'src/shared/non_provider_services/settings_service.dart';
import 'firebase_options.dart';

/// Main entry point of the Flutter application
void main() async {
  /// Ensure Flutter's widget binding is initialized before Firebase or any other async calls
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize the settings change notifier by providing the SettingsService
  final settingsChangeNotifier = SettingsChangeNotifier(SettingsService());

  /// Load the settings from a persistent source (e.g., local storage)
  await settingsChangeNotifier.loadSettings();

  /// Initialize Firebase using platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Start the app with a MultiProvider to provide multiple ChangeNotifiers to the widget tree
  runApp(MultiProvider(
      providers: [
        /// Provider for managing authentication state changes
        ChangeNotifierProvider<AuthenticationChangeNotifier>(
          create: (_) => AuthenticationChangeNotifier(),
        ),

        /// Provider for managing application settings
        ChangeNotifierProvider<SettingsChangeNotifier>.value(
          value: settingsChangeNotifier,
        ),
      ],

      /// Use a Consumer to listen to changes in the AuthenticationChangeNotifier
      child: Consumer<AuthenticationChangeNotifier>(
        builder: (context, authProvider, child) {
          /// If the user is logged in, show the authenticated part of the app (AuthedApp)
          if (authProvider.userLoggedIn) {
            return AuthedApp();
          } else {
            /// If the user is not logged in, show the non-authenticated part (NonAuthedApp)
            return const NonAuthedApp();
          }
        },
      )));
}
