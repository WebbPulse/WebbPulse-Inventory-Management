import 'package:flutter/material.dart';

/// A ChangeNotifier that manages the selection of an organization member (orgMemberId)
class OrgMemberSelectorChangeNotifier extends ChangeNotifier {
  /// Private field to store the currently selected organization member ID
  String _orgMemberId = '';

  /// Getter to access the currently selected organization member ID
  String get orgMemberId => _orgMemberId;

  /// Method to select an organization member by setting the orgMemberId
  void selectOrgMember(String orgMemberId) {
    _orgMemberId = orgMemberId;
    notifyListeners();

    /// Notify listeners (e.g., UI components) that the selected organization member has changed
  }

  /// Method to clear the selected organization member, resetting the orgMemberId to an empty string
  void clearSelectedOrgMember() {
    _orgMemberId = '';
    notifyListeners();

    /// Notify listeners that the organization member selection has been cleared
  }
}
