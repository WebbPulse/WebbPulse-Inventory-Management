import 'package:flutter/material.dart';

class OrgSelectorChangeNotifier extends ChangeNotifier {
  String _selectedOrgId = '';
  String get selectedOrgId => _selectedOrgId;

  void selectOrg(String orgId) {
    _selectedOrgId = orgId;
    notifyListeners();
  }

  void clearSelectedOrg() {
    _selectedOrgId = '';
    notifyListeners();
  }
}
