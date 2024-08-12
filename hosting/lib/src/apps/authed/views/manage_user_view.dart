import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webbcheck/src/shared/providers/firestoreService.dart';
import 'package:webbcheck/src/shared/providers/orgMemberSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/providers/orgSelectorChangeNotifier.dart';
import 'package:webbcheck/src/shared/widgets.dart';
import 'package:webbcheck/src/shared/helpers/asyncContextHelpers.dart';

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
            ? StreamBuilder<DocumentSnapshot?>(
                stream: firestoreService.getOrgMember(orgSelectorProvider.orgId,
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
                  final DocumentSnapshot orgMemberData = snapshot.data!;
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
                              if (orgMemberData['orgMemberPhotoURL'] != null)
                                CircleAvatar(
                                  radius: 75,
                                  backgroundImage: NetworkImage(
                                      orgMemberData['orgMemberPhotoURL']!),
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
                              UserRoleDropdownButton(
                                  orgMemberData: orgMemberData),
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
                                StreamBuilder<List<DocumentSnapshot>>(
                                  stream: firestoreService.getOrgMemberDevices(
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

class UserRoleDropdownButton extends StatefulWidget {
  final DocumentSnapshot orgMemberData;

  const UserRoleDropdownButton({required this.orgMemberData, Key? key})
      : super(key: key);

  @override
  _UserRoleDropdownButtonState createState() => _UserRoleDropdownButtonState();
}

class _UserRoleDropdownButtonState extends State<UserRoleDropdownButton> {
  String? selectedValue;
  List<String> items = ['Org Admin', 'Org Member'];
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.orgMemberData['orgMemberRole'];
  }

  void dispose() {
    super.dispose();
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
          hint: Text('Role'),
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
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
