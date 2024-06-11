// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:webbpulse_checkout/src/app.dart';
import 'package:webbpulse_checkout/src/services/providers/settings_controller.dart';
import 'package:webbpulse_checkout/src/services/settings_service.dart';

void main() async {
  testWidgets('Basic rendering', (tester) async {
    final settingsController = SettingsController(SettingsService());
    await settingsController.loadSettings();
    // Build our app and trigger a frame.
    await tester.pumpWidget(App(settingsController: settingsController));

    // Verify that our counter starts at 0.
    expect(find.text('Firebase Meetup'), findsOneWidget);
    expect(find.text('January 1st'), findsNothing);
  });
}
