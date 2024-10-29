import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';

class CustomSignInView extends StatelessWidget {
  final String? token;

  const CustomSignInView({super.key, this.token});

  static const routeName = '/custom-signin';

  @override
  Widget build(BuildContext context) {
    if (token != null) {
      final authProvider =
          Provider.of<AuthenticationChangeNotifier>(context, listen: false);
      authProvider.signInWithCustomToken(token!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Custom Sign-In")),
      body: Center(
        child: token != null
            ? const CircularProgressIndicator()
            : const Text("No token found in the URL"),
      ),
    );
  }
}
