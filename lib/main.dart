import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app.dart';
import 'src/providers/settingsProvider.dart';
import 'src/services/settingsService.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider(SettingsService());
  await settingsProvider.loadSettings();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(App(
    settingsProvider: settingsProvider,
  ));
}
