import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';
import 'package:webbcheck/src/shared/providers/org_member_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbcheck/src/shared/widgets.dart';
import 'package:webbcheck/src/shared/helpers/async_context_helpers.dart';

class OrgMemberView extends StatelessWidget {
  const OrgMemberView({super.key});
  static const routeName = '/manage-user';

  @override
  Widget build(BuildContext context) {
    return Consumer5<
            OrgSelectorChangeNotifier,
            OrgMemberSelectorChangeNotifier,
            FirestoreReadService,
            FirebaseFunctions,
            AuthenticationChangeNotifier>(
        builder: (context,
            orgSelectorChangeNotifier,
            orgMemberSelectorProvider,
            firestoreService,
            firebaseFunctions,
            authenticationChangeNotifier,
            child) {
      return AuthClaimChecker(
        builder: (context, userClaims) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Manage User'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  /// Clear the selected org member
                  orgMemberSelectorProvider.clearSelectedOrgMember();
                  Navigator.pop(context);
                },
              ),
            ),
            body: orgSelectorChangeNotifier.orgId.isNotEmpty &&
                    orgMemberSelectorProvider.orgMemberId.isNotEmpty
                ? StreamBuilder<DocumentSnapshot?>(
                    stream: firestoreService.getOrgMemberDocument(
                        orgSelectorChangeNotifier.orgId,
                        orgMemberSelectorProvider.orgMemberId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading user data'));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(child: Text('User not found'));
                      }
                      final DocumentSnapshot orgMemberData = snapshot.data!;
                      if (orgMemberData['orgMemberDeleted'] == true) {
                        return const Center(child: Text('User not found'));
                      }
                      return LayoutBuilder(builder: (context, constraints) {
                        double containerWidth;

                        if (constraints.maxWidth < 600) {
                          // Mobile width (under 600px)
                          containerWidth =
                              MediaQuery.of(context).size.width * 0.35;
                        } else if (constraints.maxWidth < 1200) {
                          // Tablet width (under 1200px)
                          containerWidth =
                              MediaQuery.of(context).size.width * 0.25;
                        } else {
                          // Larger screen width (over 600px)
                          containerWidth =
                              MediaQuery.of(context).size.width * 0.15;
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
                                    '${orgMemberData['orgMemberDisplayName']}',
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
                                  if (orgMemberData['orgMemberPhotoURL'] !=
                                          '' &&
                                      orgMemberData['orgMemberPhotoURL'] !=
                                          null)
                                    ProfileAvatar(
                                        photoUrl:
                                            orgMemberData['orgMemberPhotoURL'])
                                  else
                                    CircleAvatar(
                                      radius: 75,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  if (userClaims[
                                          'org_admin_${orgSelectorChangeNotifier.orgId}'] ==
                                      true)
                                    Column(
                                      children: [
                                        UserRoleDropdownButton(
                                            orgMemberData: orgMemberData),
                                        const SizedBox(height: 8),
                                        DeleteUserButton(
                                            orgMemberData: orgMemberData),
                                      ],
                                    )
                                  else
                                    UserRoleCard(orgMemberData: orgMemberData),
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
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    StreamBuilder<List<DocumentSnapshot>>(
                                      stream: firestoreService
                                          .getOrgMemberDevicesDocuments(
                                              orgSelectorChangeNotifier.orgId,
                                              orgMemberSelectorProvider
                                                  .orgMemberId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          return const Center(
                                              child: Text(
                                                  'Error loading devices'));
                                        }

                                        // Handle case where snapshot.data might be null or empty
                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Center(
                                              child: Text('No devices found'));
                                        }

                                        final List<DocumentSnapshot>
                                            devicesDocs = snapshot.data!;

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
        },
      );
    });
  }
}

class DeleteUserButton extends StatefulWidget {
  const DeleteUserButton({
    super.key,
    required this.orgMemberData,
  });

  final DocumentSnapshot<Object?> orgMemberData;

  @override
  State<DeleteUserButton> createState() => _DeleteUserButtonState();
}

class _DeleteUserButtonState extends State<DeleteUserButton> {
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPressed() async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    final authenticationChangeNotifier =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      String orgMemberId = widget.orgMemberData['orgMemberId'];
      await firebaseFunctions.httpsCallable('delete_org_member_callable').call({
        'orgId': orgSelectorProvider.orgId,
        'orgMemberId': widget.orgMemberData.id,
      });
      if (orgMemberId == authenticationChangeNotifier.user?.uid) {
        authenticationChangeNotifier.signOutUser();
      }
      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'User deleted successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to delete user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FirebaseFunctions, OrgSelectorChangeNotifier,
            AuthenticationChangeNotifier>(
        builder: (context, firebaseFunctions, orgSelectorChangeNotifier,
            authenticationChangeNotifier, child) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _onPressed,
        icon: _isLoading
            ? const CircularProgressIndicator()
            : const Icon(Icons.delete),
        label: Wrap(children: [
          Text(
            'Delete User',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ]),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.red,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.all(16.0),
        ),
      );
    });
  }
}

class UserRoleCard extends StatelessWidget {
  final DocumentSnapshot orgMemberData;

  const UserRoleCard({required this.orgMemberData, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              orgMemberData['orgMemberRole'] == 'admin'
                  ? 'Org Admin'
                  : ' Org Member',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class UserRoleDropdownButton extends StatefulWidget {
  final DocumentSnapshot orgMemberData;

  const UserRoleDropdownButton({required this.orgMemberData, super.key});

  @override
  UserRoleDropdownButtonState createState() => UserRoleDropdownButtonState();
}

class UserRoleDropdownButtonState extends State<UserRoleDropdownButton> {
  String? selectedValue;
  bool _isLoading = false;

  final List<Map<String, String>> items = [
    {'value': 'admin', 'display': 'Org Admin'},
    {'value': 'member', 'display': 'Org Member'},
  ];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.orgMemberData['orgMemberRole'];
  }

  void _onChanged() async {
    final orgSelectorProvider =
        Provider.of<OrgSelectorChangeNotifier>(context, listen: false);
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseFunctions.httpsCallable('update_user_role_callable').call({
        "orgMemberRole": selectedValue,
        "orgMemberId": widget.orgMemberData.id,
        "orgId": orgSelectorProvider.orgId,
      });

      AsyncContextHelpers.showSnackBarIfMounted(
          context, 'User role updated successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to update user role: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButton<String>(
          value: selectedValue,
          hint: const Text('Role'),
          elevation: 16,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            setState(() {
              selectedValue = newValue;
            });
            _isLoading ? null : _onChanged();
          },
          items:
              items.map<DropdownMenuItem<String>>((Map<String, String> item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['display']!),
            );
          }).toList(),
        ),
      ),
    );
  }
}
