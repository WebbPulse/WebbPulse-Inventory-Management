import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // Firebase UI for authentication
import 'package:provider/provider.dart';

import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/apps/authed/views/org_selected/device_checkout_view.dart';

/// SignInView is the screen where users can sign in using Firebase UI.
class SignInView extends StatelessWidget {
  const SignInView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/signin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'), // Display title in the AppBar
      ),
      body: Center(
        // Use Consumer to listen for changes in AuthenticationChangeNotifier
        child: Consumer<AuthenticationChangeNotifier>(
          builder: (context, authProvider, child) => SignInScreen(
            // Define the authentication providers (e.g., email-based authentication)
            providers: [
              EmailAuthProvider(), // Enable email/password sign-in
            ],
            // Define actions based on authentication state changes
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                // If the user signs in successfully, navigate to DeviceCheckoutView
                Navigator.pushNamed(context, DeviceCheckoutView.routeName);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
