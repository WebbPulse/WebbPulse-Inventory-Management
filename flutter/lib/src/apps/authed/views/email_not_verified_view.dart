import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:webbpulse_inventory_management/src/apps/authed/views/verify_email_view.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';

/// EmailNotVerifiedView provides the screen for if a user is not currently email verified. 
/// It offers options for users to either verify or log out.
class EmailNotVerifiedView extends StatelessWidget {
  const EmailNotVerifiedView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/email-not-verified';

  @override
  Widget build(BuildContext context) {
    // Retrieve the current theme to style widgets accordingly
    final theme = Theme.of(context);

    return Consumer<AuthenticationChangeNotifier>(
      builder:(context, authenticationChangeNotifier, child){ 
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
                                  'Please Verify Your Email Address', // heading text
                                  style: theme.textTheme
                                      .titleLarge, // Use theme's large text style
                                ),
                              ),
                            ),
                            // CustomCard for Register option
                            CustomCard(
                              theme:
                                  theme, // Pass the theme for consistent styling
                              customCardLeading: Icon(Icons.mail,
                                  color: theme.colorScheme
                                      .secondary), // Leading icon for the card
                              customCardTitle: const Text(
                                  'Verify Email'), // Title text for the card
                              customCardTrailing: null, // No trailing widget
                              onTapAction: () {
                                // Navigate to the VerifyEmailView when the card is tapped
                                Navigator.pushNamed(
                                    context, VerifyEmailView.routeName);
                              },
                            ),
                            CustomCard(
                              theme:
                                  theme, // Pass the theme for consistent styling
                              customCardLeading: Icon(Icons.logout,
                                  color: theme.colorScheme
                                      .secondary), // Leading icon for the card
                              customCardTitle: const Text(
                                  'Sign Out'), // Title text for the card
                              customCardTrailing: null, // No trailing widget
                              onTapAction: () {
                                // Sign out the user when the card is tapped
                                authenticationChangeNotifier.signOutUser();
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
    );
  }
}