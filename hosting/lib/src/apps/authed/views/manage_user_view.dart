import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webbcheck/src/shared/providers/firestoreService.dart';
import 'package:webbcheck/src/shared/providers/orgMemberSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/providers/orgSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/widgets.dart';

class ManageUserView extends StatelessWidget {
  const ManageUserView({super.key});
  static const routeName = '/manage-user';

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgSelectorChangeNotifier, OrgMemberSelectorChangeNotifier,
            FirestoreService>(
        builder: (context, orgSelectorProvider, orgMemberSelectorProvider,
            firestoreService, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage User'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              /// Clear the selected org member
              orgMemberSelectorProvider.clearSelectedOrgMember();
              Navigator.pop(context);
            },
          ),
        ),
        body: orgSelectorProvider.orgId.isNotEmpty &&
                orgMemberSelectorProvider.orgMemberId.isNotEmpty
            ? StreamBuilder<DocumentSnapshot>(
                stream: firestoreService.getOrgMemberStream(
                    orgSelectorProvider.orgId,
                    orgMemberSelectorProvider.orgMemberId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading user data'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('User not found'));
                  }
                  final DocumentSnapshot orgMember = snapshot.data!;
                  return LayoutBuilder(builder: (context, constraints) {
                    double containerWidth;

                    if (constraints.maxWidth < 600) {
                      // Mobile width (under 600px)
                      containerWidth = MediaQuery.of(context).size.width * 0.35;
                    } else {
                      // Larger screen width (over 600px)
                      containerWidth = MediaQuery.of(context).size.width * 0.2;
                    }
                    return Row(
                      children: [
                        // Right-side column pane
                        Container(
                          width: containerWidth,
                          color: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'User Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${orgMember['orgMemberDisplayName']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary),
                              ),
                              const SizedBox(height: 16),
                              if (orgMember['orgMemberPhotoURL'] != null)
                                CircleAvatar(
                                  radius: 75,
                                  backgroundImage: NetworkImage(
                                      orgMember['orgMemberPhotoURL']!),
                                )
                              else
                                const CircleAvatar(
                                  radius: 75,
                                  backgroundColor: Colors.grey,
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                'Role:\n Lets say this is a role',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle button press
                                },
                                child: const Text('Manage Role'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checked Out Devices',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                FutureBuilder<List<DocumentSnapshot>>(
                                  future: firestoreService.getOrgMemberDevices(
                                      orgSelectorProvider.orgId,
                                      orgMemberSelectorProvider.orgMemberId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return const Center(
                                          child: Text('Error loading devices'));
                                    }

                                    // Handle case where snapshot.data might be null or empty
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                          child: Text('No devices found'));
                                    }

                                    final List<DocumentSnapshot> devicesDocs =
                                        snapshot.data!;

                                    return Expanded(
                                      // Ensure FutureBuilder's content gets proper layout constraints
                                      child: DeviceList(
                                        devicesDocs: devicesDocs,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  });
                },
              )

            /// If the orgId or orgMemberId is empty due to pressing the back button, show a loading screen.
            : const Center(child: CircularProgressIndicator()),
      );
    });
  }
}
