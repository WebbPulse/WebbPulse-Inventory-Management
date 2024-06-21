import 'package:flutter/material.dart';

class OrganizationsProvider extends ChangeNotifier {
  List<String> _organizationUids = [];
  List<String> get organizationUids => _organizationUids;

  void setOrganizations(List<String> orgUids) {
    _organizationUids = orgUids;
    notifyListeners();
  }
}
