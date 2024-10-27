import 'package:flutter/foundation.dart';
import 'dart:io';

class PlatformChangeNotifier extends ChangeNotifier {
  PlatformChangeNotifier() {
    _init();
  }

  bool _isios = false;
  bool _isipad = false;
  bool _isandroid = false;
  bool _isweb = false;

  bool get isIOS => _isios;
  bool get isIPad => _isipad;
  bool get isAndroid => _isandroid;
  bool get isWeb => _isweb;

  void _init() {
    _isweb = kIsWeb;

    if (!_isweb) {
      _isios = Platform.isIOS;
      _isandroid = Platform.isAndroid;
    }
  }
}
