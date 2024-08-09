import 'package:flutter/material.dart';

class OrgMemberSelectorChangeNotifier extends ChangeNotifier {
  String _selectedOrgMemberId = '';
  String get selectedOrgMemberId => _selectedOrgMemberId;

  void selectOrgMember(String OrgMemberId) {
    _selectedOrgMemberId = OrgMemberId;
    notifyListeners();
  }

  void clearSelectedOrgMember() {
    _selectedOrgMemberId = '';
    notifyListeners();
  }
}
