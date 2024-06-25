import 'package:flutter/material.dart';

class OrgSelectorProvider extends ChangeNotifier {
  String _selectedOrg = '';
  String get selectedOrg => _selectedOrg;

  void selectOrg(String orgUid) {
    _selectedOrg = orgUid;
    notifyListeners();
  }
}
