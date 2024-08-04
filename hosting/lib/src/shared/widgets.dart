// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../apps/authed/views/org_selection_view.dart';

import '../apps/authed/views/profile_view.dart';
import '../apps/authed/views/settings_view.dart';
import '../apps/authed/views/checkout_view.dart';
import '../apps/authed/views/devices_view.dart';
import '../apps/authed/views/users_view.dart';

class AuthedDrawer extends StatelessWidget {
  const AuthedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text('Menu'),
          ),
          ListTile(
            title: const Text('Checkout'),
            onTap: () {
              Navigator.pushNamed(context, CheckoutView.routeName);
            },
          ),
          ListTile(
            title: const Text('Devices'),
            onTap: () {
              Navigator.pushNamed(context, DevicesView.routeName);
            },
          ),
          ListTile(
            title: const Text('Users'),
            onTap: () {
              Navigator.pushNamed(context, UsersView.routeName);
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, SettingsView.routeName);
            },
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, ProfileView.routeName);
            },
          ),
          ListTile(
            title: const Text('Organizations'),
            onTap: () {
              Navigator.pushNamed(context, OrgSelectionView.routeName);
            },
          ),
        ],
      ),
    );
  }
}

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
      required this.titleText,
      required this.customCardTrailing,
      required this.onTapAction});
  final ThemeData theme;
  final dynamic customCardLeading;
  final String titleText;
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
          title: Text(
            titleText,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          trailing: customCardTrailing,
          onTap: onTapAction,
        ),
      );
}

class CustomLayoutBuilder extends StatelessWidget {
  const CustomLayoutBuilder({super.key, required this.childWidget});
  final Widget childWidget;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double widthFactor;
              if (constraints.maxWidth < 600) {
                widthFactor = 0.9; // 90% of the width for narrow screens
              } else if (constraints.maxWidth < 1200) {
                widthFactor = 0.5; // 70% of the width for medium screens
              } else {
                widthFactor = 0.2; // 50% of the width for large screens
              }
              return SizedBox(
                  width: constraints.maxWidth * widthFactor,
                  child: childWidget);
            },
          ),
        ),
      );
}
