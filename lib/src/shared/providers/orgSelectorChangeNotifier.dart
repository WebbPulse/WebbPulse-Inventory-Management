import 'package:flutter/material.dart';

class OrgSelectorChangeNotifier extends ChangeNotifier {
  String _selectedOrgUid = '';
  String get selectedOrgId => _selectedOrgUid;

  void selectOrg(String orgUid) {
    _selectedOrgUid = orgUid;
    notifyListeners();
  }

  void clearSelectedOrg() {
    _selectedOrgUid = '';
    notifyListeners();
  }
}
