import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/users_screen.dart';



class ScaffoldWithDrawer extends StatelessWidget {
  final String title;
  final Widget body;

  const ScaffoldWithDrawer({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
       drawer: Drawer(
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
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, HomeScreen.routeName);
              },
            ),
            ListTile(
              title: const Text('Checkout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CheckoutScreen.routeName);
              },
            ),
            ListTile(
              title: const Text('Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, DevicesScreen.routeName);
              },
            ),
            ListTile(
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, UsersScreen.routeName);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SettingsScreen.routeName);
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, ProfilePage.routeName);
              },
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}