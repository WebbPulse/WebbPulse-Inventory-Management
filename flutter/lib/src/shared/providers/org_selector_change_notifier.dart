import 'package:flutter/material.dart';

/// A ChangeNotifier that manages the selection of an organization (orgId)
class OrgSelectorChangeNotifier extends ChangeNotifier {
  OrgSelectorChangeNotifier () {
    init();
  }
  
  String _orgId = '';

  String get orgId => _orgId;

  void init() {
    _orgId = ''; // Already empty by default, so no need to notify here.
    // notifyListeners(); // Remove this call
  }

  /// Method to select an organization by setting the orgId
  void selectOrg(String orgId) {
    if (_orgId != orgId) {
      _orgId = orgId;
      notifyListeners(); // Notify listeners only if the value has changed
    }
  }

  /// Method to clear the selected organization, resetting the orgId to an empty string
  void clearSelectedOrg() {
    if (_orgId.isNotEmpty) {
      _orgId = '';
      notifyListeners(); // Notify listeners only if the value was not already empty
    }
  }
}
