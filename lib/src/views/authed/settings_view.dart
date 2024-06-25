import 'package:flutter/material.dart';

import '../../providers/settingsProvider.dart';
import '../../widgets.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settingsProvider});

  static const routeName = '/settings';

  final SettingsProvider settingsProvider;

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithDrawer(
      title: 'Settings',
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: DropdownButton<ThemeMode>(
          // Read the selected themeMode from the controller
          value: settingsProvider.themeMode,
          // Call the updateThemeMode method any time the user selects a theme.
          onChanged: settingsProvider.updateThemeMode,
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark Theme'),
            )
          ],
        ),
      ),
    );
  }
}
