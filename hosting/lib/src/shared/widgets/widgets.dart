import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header(this.heading, {super.key});
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          heading,
          style: const TextStyle(fontSize: 24),
        ),
      );
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 18),
        ),
      );
}

class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail, {super.key});
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: 18),
            )
          ],
        ),
      );
}

class CustomCard extends StatelessWidget {
  const CustomCard(
      {super.key,
      required this.theme,
      required this.customCardLeading,
      required this.customCardTitle,
      required this.customCardTrailing,
      required this.onTapAction});
  final ThemeData theme;
  final dynamic customCardLeading;
  final dynamic customCardTitle;
  final dynamic customCardTrailing;
  final dynamic onTapAction;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          tileColor: theme.colorScheme.secondary.withOpacity(0),
          leading: customCardLeading,
          title: customCardTitle,
          trailing: customCardTrailing,
          onTap: onTapAction,
        ),
      );
}

class SmallLayoutBuilder extends StatelessWidget {
  const SmallLayoutBuilder({super.key, required this.childWidget});
  final Widget childWidget;

  @override
  Widget build(BuildContext context) {
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0.0;
    final topPadding = MediaQuery.of(context).padding.top;
    final availableHeight =
        MediaQuery.of(context).size.height - appBarHeight - topPadding;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight,
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double widthFactor;
            if (constraints.maxWidth < 600) {
              widthFactor = 0.95; // 90% of the width for narrow screens
            } else if (constraints.maxWidth < 1200) {
              widthFactor = 0.5; // 50% of the width for medium screens
            } else {
              widthFactor = 0.2; // 20% of the width for large screens
            }
            return SizedBox(
              width: constraints.maxWidth * widthFactor,
              child: childWidget,
            );
          },
        ),
      ),
    );
  }
}

class AsyncContextHelpers {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> showSnackBarIfMounted(
      BuildContext context, String message) async {
    while (!context.mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (context.mounted) {
      showSnackBar(context, message);
    }
  }

  static Future<void> popContextIfMounted(BuildContext context) async {
    while (!context.mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}




