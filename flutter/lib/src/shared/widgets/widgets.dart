import 'package:flutter/material.dart';

/// A simple widget for displaying a heading with some padding
class Header extends StatelessWidget {
  const Header(this.heading, {super.key});
  final String heading; // The text for the heading

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0), // Add padding around the text
        child: Text(
          heading,
          style: const TextStyle(fontSize: 24), // Set font size for heading
        ),
      );
}

/// A widget for displaying a paragraph with some padding and a larger font size
class Paragraph extends StatelessWidget {
  const Paragraph(this.content, {super.key});
  final String content; // The text content for the paragraph

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4), // Add horizontal and vertical padding
        child: Text(
          content,
          style:
              const TextStyle(fontSize: 18), // Set font size for paragraph text
        ),
      );
}

/// A widget that displays an icon followed by some text in a row
class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail, {super.key});
  final IconData icon; // The icon to display
  final String detail; // The detail text to display next to the icon

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0), // Add padding around the row
        child: Row(
          children: [
            Icon(icon), // Display the provided icon
            const SizedBox(width: 8), // Add space between the icon and text
            Text(
              detail,
              style: const TextStyle(
                  fontSize: 18), // Set font size for the detail text
            )
          ],
        ),
      );
}

/// A customizable card widget that allows setting a leading icon, title, trailing widget, and tap action
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.theme, // Theme data for styling the card
    required this.customCardLeading, // Custom leading widget (e.g., icon)
    required this.customCardTitle, // Title text or widget for the card
    required this.customCardTrailing, // Trailing widget (e.g., button)
    required this.onTapAction, // Tap action for the card
  });

  final ThemeData theme; // Theme data to style the card
  final dynamic customCardLeading; // Widget for the leading part of the card
  final dynamic customCardTitle; // Title or text widget
  final dynamic customCardTrailing; // Trailing widget
  final dynamic onTapAction; // Action when the card is tapped

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(
            vertical: 8.0), // Vertical margin between cards
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0), // Padding inside the ListTile
          tileColor: theme.colorScheme.secondary
              .withOpacity(0), // Background color with transparency
          leading: customCardLeading, // Leading icon or widget
          title: customCardTitle, // Title or main content
          trailing: customCardTrailing, // Trailing widget (e.g., button)
          onTap: onTapAction, // Tap action for the card
        ),
      );
}

/// A layout builder that adjusts the width of the child widget based on screen size
class SmallLayoutBuilder extends StatelessWidget {
  const SmallLayoutBuilder({super.key, required this.childWidget});

  final Widget
      childWidget; // The widget to be resized based on layout constraints

  @override
  Widget build(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ??
        0.0; // Get the height of the app bar, if present
    final topPadding = MediaQuery.of(context)
        .padding
        .top; // Get the top padding (e.g., status bar height)
    final availableHeight = MediaQuery.of(context).size.height -
        appBarHeight -
        topPadding; // Calculate available height

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight, // Constrain the height to available space
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double
                widthFactor; // Factor to control the width based on screen size
            if (constraints.maxWidth < 600) {
              widthFactor = 0.95; // 95% width for narrow screens
            } else if (constraints.maxWidth < 1200) {
              widthFactor = 0.5; // 50% width for medium screens
            } else {
              widthFactor = 0.2; // 20% width for large screens
            }
            return SizedBox(
              width: constraints.maxWidth *
                  widthFactor, // Adjust width based on screen size
              child:
                  childWidget, // Display the child widget with adjusted width
            );
          },
        ),
      ),
    );
  }
}

/// Helper class for managing context-related asynchronous tasks
class AsyncContextHelpers {
  /// Display a SnackBar with a message
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message))); // Show a SnackBar with the provided message
  }

  /// Display a SnackBar only if the context is mounted (i.e., still valid)
  static Future<void> showSnackBarIfMounted(
      BuildContext context, String message) async {
    while (!context.mounted) {
      await Future.delayed(const Duration(
          milliseconds: 100)); // Wait until the context is mounted
    }
    if (context.mounted) {
      showSnackBar(context, message); // Show SnackBar if context is valid
    }
  }

  /// Pop the current context (e.g., close a dialog) only if the context is mounted
  static Future<void> popContextIfMounted(BuildContext context) async {
    while (!context.mounted) {
      await Future.delayed(const Duration(
          milliseconds: 100)); // Wait until the context is mounted
    }
    if (context.mounted) {
      Navigator.of(context)
          .pop(); // Pop the context (e.g., close the current screen or dialog)
    }
  }
}
