import 'package:flutter/material.dart';
import 'register_view.dart';
import 'signin_view.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';

/// LandingView provides the initial landing screen for the app.
/// It offers options for users to either register or sign in.
class LandingView extends StatelessWidget {
  const LandingView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    // Retrieve the current theme to style widgets accordingly
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image that fills the entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/boxes.jpg', // Path to your background image asset
              fit:
                  BoxFit.cover, // Ensures the image covers the whole background
            ),
          ),
          // Centered content with constrained size
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context)
                    .size
                    .height, // Constrain the height to screen size
              ),
              child: Center(
                // SmallLayoutBuilder adjusts layout based on screen size
                child: SmallLayoutBuilder(
                  childWidget: Card(
                    color: theme.colorScheme
                        .onPrimary, // Set the card's background color
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0), // Vertical margin around the card
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0), // Padding inside the card
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center the content vertically
                        mainAxisSize:
                            MainAxisSize.min, // Shrink to fit the content
                        children: [
                          // Title card displaying the app name
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical:
                                      8.0), // Padding inside the title card
                              child: Text(
                                'WebbPulse Inventory Management', // App name displayed as title
                                style: theme.textTheme
                                    .titleLarge, // Use theme's large text style
                              ),
                            ),
                          ),
                          // CustomCard for Register option
                          CustomCard(
                            theme:
                                theme, // Pass the theme for consistent styling
                            customCardLeading: Icon(Icons.login,
                                color: theme.colorScheme
                                    .secondary), // Leading icon for the card
                            customCardTitle: const Text(
                                'Register'), // Title text for the card
                            customCardTrailing: null, // No trailing widget
                            onTapAction: () {
                              // Navigate to the RegisterView when the card is tapped
                              Navigator.pushNamed(
                                  context, RegisterView.routeName);
                            },
                          ),
                          // CustomCard for Sign In option
                          CustomCard(
                            theme:
                                theme, // Pass the theme for consistent styling
                            customCardLeading: Icon(Icons.login,
                                color: theme.colorScheme
                                    .secondary), // Leading icon for the card
                            customCardTitle: const Text(
                                'Sign In'), // Title text for the card
                            customCardTrailing: null, // No trailing widget
                            onTapAction: () {
                              // Navigate to the SignInView when the card is tapped
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
