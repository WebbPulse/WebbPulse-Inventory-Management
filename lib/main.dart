// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/authentication_state.dart';
import 'src/app.dart';
import 'src/providers/settings_controller.dart';
import 'src/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(ChangeNotifierProvider(
    create: (context) => AuthenticationState(),
    builder: ((context, child) => App(settingsController: settingsController)),
  ));
}
