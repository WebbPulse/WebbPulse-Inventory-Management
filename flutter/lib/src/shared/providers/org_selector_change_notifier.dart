import 'package:flutter/material.dart';

/// A ChangeNotifier that manages the selection of an organization (orgId)
class OrgSelectorChangeNotifier extends ChangeNotifier {
  /// Private field to store the currently selected organization ID
  String _orgId = '';

  /// Getter to access the currently selected organization ID
  String get orgId => _orgId;

  /// Method to select an organization by setting the orgId
  void selectOrg(String orgId) {
    _orgId = orgId;
    notifyListeners();

    /// Notify listeners (e.g., widgets) that the selected organization has changed
  }

  /// Method to clear the selected organization, resetting the orgId to an empty string
  void clearSelectedOrg() {
    _orgId = '';
    notifyListeners();

    /// Notify listeners that the organization selection has been cleared
  }
}
