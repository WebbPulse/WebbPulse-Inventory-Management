import 'package:flutter/material.dart';

class OrgSelectorChangeNotifier extends ChangeNotifier {
  String _orgId = '';
  String get orgId => _orgId;

  void selectOrg(String orgId) {
    _orgId = orgId;
    notifyListeners();
  }

  void clearSelectedOrg() {
    _orgId = '';
    notifyListeners();
  }
}
