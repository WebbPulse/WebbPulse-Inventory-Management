import 'package:flutter/material.dart';
import 'register_view.dart';
import 'signin_view.dart';
import 'package:webbcheck/src/shared/widgets.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/saber.gif', // Your image asset path
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height,
              ),
              child: Center(
                child: CustomLayoutBuilder(
                  childWidget: Card(
                    color: theme.colorScheme.onPrimary,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'WebbPulse Device Checkout',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ),
                          CustomCard(
                            theme: theme,
                            customCardLeading: Icon(Icons.login,
                                color: theme.colorScheme.secondary),
                            titleText: 'Register',
                            customCardTrailing: null,
                            onTapAction: () {
                              Navigator.pushNamed(
                                  context, RegisterView.routeName);
                            },
                          ),
                          CustomCard(
                            theme: theme,
                            customCardLeading: Icon(Icons.login,
                                color: theme.colorScheme.secondary),
                            titleText: 'Sign In',
                            customCardTrailing: null,
                            onTapAction: () {
                              Navigator.pushNamed(
                                  context, SignInView.routeName);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
