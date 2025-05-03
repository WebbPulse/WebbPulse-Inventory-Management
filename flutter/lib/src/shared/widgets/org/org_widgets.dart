import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/firestore_read_service.dart';
import '../../providers/org_selector_change_notifier.dart';

class OrgDocumentStreamBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DocumentSnapshot orgDocument)
      builder;

  const OrgDocumentStreamBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
      builder:
          (context, firestoreReadService, orgSelectorChangeNotifier, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: firestoreReadService
              .getOrgDocument(orgSelectorChangeNotifier.orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.data == null) {
              return const CircularProgressIndicator();
            }
            DocumentSnapshot orgDocument = snapshot.data!;

            return builder(context, orgDocument);
          },
        );
      },
    );
  }
}

class OrgVerkadaIntegrationDocumentStreamBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DocumentSnapshot orgDocument)
      builder;

  const OrgVerkadaIntegrationDocumentStreamBuilder(
      {super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
      builder:
          (context, firestoreReadService, orgSelectorChangeNotifier, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: firestoreReadService.getOrgVerkadaIntegrationDocument(
              orgSelectorChangeNotifier.orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.data == null) {
              return const CircularProgressIndicator();
            }
            DocumentSnapshot orgVerkadaIntegrationDocument = snapshot.data!;

            return builder(context, orgVerkadaIntegrationDocument);
          },
        );
      },
    );
  }
}

/// A custom AppBar widget that displays the organization name from Firestore in the title
class OrgNameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleSuffix; // Optional suffix for the title
  final List<Widget> actions; // List of widgets for AppBar actions
  final Widget? leading; // Optional widget for the leading part of the AppBar

  const OrgNameAppBar({
    super.key,
    this.titleSuffix = '', // Default empty suffix for the title
    this.actions = const [], // Default empty list of actions
    this.leading, // Optional leading widget
  });

  @override
  Widget build(BuildContext context) {
    // Use OrgDocumentStreamBuilder to fetch and display the organization name
    return OrgDocumentStreamBuilder(
      builder: (context, orgDocument) {
        final String orgName = orgDocument['orgName'] ??
            ''; // Get organization name from the document

        return AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$orgName $titleSuffix'),
          ), // Display the organization name with the title suffix
          actions: actions, // Set the AppBar actions
          leading: leading, // Set the leading widget if provided
        );
      },
    );
  }

  // Define the preferred size of the AppBar to match the default toolbar height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
