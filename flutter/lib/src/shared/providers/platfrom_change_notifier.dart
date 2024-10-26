import 'package:flutter/material.dart';


class PlatfromChangeNotifier extends ChangeNotifier {
  PlatfromChangeNotifier() {
    init();
  }
  
  String _platformName = '';
  String get platformName => _platformName;

  void init() {
    _platformName = 'Flutter';
    notifyListeners();
  }
}