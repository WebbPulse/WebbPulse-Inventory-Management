import 'package:flutter/material.dart';
import '../non_provider_services/settings_service.dart';

/// A ChangeNotifier that manages the app's settings, such as the theme mode
class SettingsChangeNotifier with ChangeNotifier {
  /// Constructor to initialize the SettingsService
  SettingsChangeNotifier(this._settingsService);

  /// The service responsible for handling the app's settings (e.g., theme mode)
  final SettingsService _settingsService;

  /// Private field to store the current theme mode
  late ThemeMode _themeMode;

  /// Getter to access the current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Loads the theme mode from the settings service and notifies listeners
  Future<void> loadSettings() async {
    _themeMode =
        await _settingsService.themeMode(); // Fetch the current theme mode
    notifyListeners();

    /// Notify listeners that the theme mode has been loaded/updated
  }

  /// Updates the theme mode if it has changed and notifies listeners
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    /// Do nothing if the new theme mode is null

    if (newThemeMode == _themeMode) return;

    /// Do nothing if the new theme mode is the same as the current one
    _themeMode = newThemeMode;

    /// Update the theme mode

    notifyListeners();

    /// Notify listeners that the theme mode has changed
  }
}
