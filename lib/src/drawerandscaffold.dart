import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/checkout_page.dart';
import 'pages/devices_page.dart';
import 'pages/users_page.dart';



class DrawerAndScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  DrawerAndScaffold({required this.title, required this.body});

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
              child: Text('Menu'),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, HomePage.routeName);
              },
            ),
            ListTile(
              title: Text('Checkout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CheckoutPage.routeName);
              },
            ),
            ListTile(
              title: Text('Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, DevicesPage.routeName);
              },
            ),
            ListTile(
              title: Text('Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, UsersPage.routeName);
              },
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, ProfilePage.routeName);
              },
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SettingsPage.routeName);
              },
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}