import 'package:flutter/material.dart';

class OrgSelectorProvider extends ChangeNotifier {
  String _selectedOrgUid = '';
  String get selectedOrgUid => _selectedOrgUid;

  void selectOrg(String orgUid) {
    _selectedOrgUid = orgUid;
    notifyListeners();
  }

  void clearSelectedOrg() {
    _selectedOrgUid = '';
    notifyListeners();
  }
}
