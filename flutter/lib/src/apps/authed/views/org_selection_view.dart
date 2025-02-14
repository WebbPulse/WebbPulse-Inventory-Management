import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'org_create_view.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';
import 'org_selected/org_device_list_view.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/user_widgets.dart';

/// OrgSelectionView provides the screen for selecting an organization.
/// Users can choose an organization they are part of or create a new one.
class OrgSelectionView extends StatelessWidget {
  const OrgSelectionView({super.key});

  /// Route name for navigation to this view
  static const routeName = '/select-organization';

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    // Consumer2 listens to both AuthenticationChangeNotifier and FirestoreReadService
    return Consumer2<AuthenticationChangeNotifier, FirestoreReadService>(
      builder:
          (context, authenticationChangeNotifier, firestoreService, child) =>
              // AuthClaimChecker checks the user's authentication claims
              AuthClaimChecker(builder: (context, userClaims) {
        final List<String> userOrgIds = extractOrgIdsFromClaims(
            userClaims); // Extract the user's organization IDs from claims

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading:
                false, // Disable the automatic back button
            title: const Text('My Organizations'), // AppBar title
            actions: [
              // Sign out button only appears if no organization is selected
              if (Provider.of<OrgSelectorChangeNotifier>(context).orgId == '')
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout), // Logout icon
                  label: const Text('Sign Out'),
                  onPressed: () {
                    authenticationChangeNotifier
                        .signOutUser(); // Sign out action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.surface.withOpacity(0.95),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.all(16.0),
                  ),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Column(
                  children: [
                    if (constraints.maxWidth > 600)
                      // Display heading if the screen width is larger than 600 pixels
                      Text(
                        'Select an Organization',
                        style: theme.textTheme.headlineSmall,
                      ),
                    Expanded(
                      child: userOrgIds.isNotEmpty
                          ? SmallLayoutBuilder(
                              childWidget: ListView.builder(
                                physics:
                                    const BouncingScrollPhysics(), // Adds a bounce effect when scrolling
                                itemCount: userOrgIds.length +
                                    (userOrgIds.length < 10
                                        ? 1
                                        : 0), // Display "Create New Organization" if org count is less than 10
                                itemBuilder: (context, index) {
                                  // If the last item, display the "Create New Organization" button
                                  if (index == userOrgIds.length &&
                                      userOrgIds.length < 10) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context,
                                              OrgCreateView
                                                  .routeName); // Navigate to OrgCreateView
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme
                                              .colorScheme.surface
                                              .withOpacity(0.95),
                                          side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.all(16.0),
                                        ),
                                        child: const Text(
                                            'Create New Organization'),
                                      ),
                                    );
                                  }
                                  // Display the list of organizations
                                  final orgId = userOrgIds[index];
                                  return OrgCard(
                                      orgId: orgId); // Custom OrgCard widget
                                },
                              ),
                            )
                          : Column(
                              // If no organizations are found, show this message and button
                              children: [
                                const Text('No organizations found'),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context,
                                        OrgCreateView
                                            .routeName); // Navigate to OrgCreateView
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface
                                        .withOpacity(0.95),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Text('Create New Organization'),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// OrgCard is a widget that represents an organization in the organization list.
class OrgCard extends StatelessWidget {
  const OrgCard({
    super.key,
    required this.orgId,
  });

  final String orgId; // Organization ID

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(
      builder: (context, orgSelectorProvider, firestoreService, child) {
        return StreamBuilder(
          stream: firestoreService.getOrgDocument(
              orgId), // Stream the organization document from Firestore
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Show loading spinner
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text(
                      'Error loading organizations')); // Show error message
            }

            final String orgName =
                snapshot.data?['orgName'] ?? ''; // Organization name
            final bool orgDeleted = snapshot.data?['orgDeleted'] ??
                false; // Check if the organization is deleted

            if (orgDeleted) {
              return const SizedBox
                  .shrink(); // Return empty if the organization is deleted
            }

            return CustomCard(
              theme: theme,
              customCardLeading: Icon(Icons.home,
                  color: theme.colorScheme.secondary), // Home icon
              customCardTitle: Text(orgName), // Display the organization name
              customCardTrailing: null,
              onTapAction: () {
                orgSelectorProvider.selectOrg(orgId); // Select the organization
                Navigator.pushNamed(
                    context,
                    OrgDeviceListView
                        .routeName); // Navigate to DeviceCheckoutView
              },
            );
          },
        );
      },
    );
  }
}

/// Extracts organization IDs from the user's authentication claims.
List<String> extractOrgIdsFromClaims(Map<String, dynamic> claims) {
  final RegExp orgIdPattern = RegExp(
      r'^org_(member|admin|deskstation)_(\w+)$'); // Regular expression pattern for extracting org IDs
  List<String> orgIds = [];

  claims.forEach((key, value) {
    final match = orgIdPattern.firstMatch(key);
    if (match != null) {
      final orgId = match.group(2);
      if (orgId != null) {
        orgIds.add(orgId); // Add the extracted org ID to the list
      }
    }
  });

  return orgIds; // Return the list of organization IDs
}
