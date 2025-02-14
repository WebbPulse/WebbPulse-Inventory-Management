import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';

class CheckoutUserListDialog extends StatefulWidget {
  final bool isDeviceCheckedOut;
  final String orgId;
  final String deviceCheckedOutNote;
  final ValueChanged<String> onUserSelected; // Callback with the selected userId

  const CheckoutUserListDialog({
    super.key,
    required this.isDeviceCheckedOut,
    required this.orgId,
    required this.deviceCheckedOutNote,
    required this.onUserSelected,
  });

  @override
  _CheckoutUserListDialogState createState() => _CheckoutUserListDialogState();
}

class _CheckoutUserListDialogState extends State<CheckoutUserListDialog> {
  late TextEditingController _userSearchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userSearchController = TextEditingController();
    _userSearchController.addListener(() {
      setState(() {
        _searchQuery = _userSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.isDeviceCheckedOut
          ? 'Confirm Check-out User'
          : 'Confirm Check-in User'),
      content: Consumer2<FirestoreReadService, OrgSelectorChangeNotifier>(
        builder: (context, firestoreReadService, orgSelectorChangeNotifier, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isDeviceCheckedOut
                    ? 'Select the user to check-out this device.'
                    : 'Select the user to check-in this device.',
              ),
              TextField(
                controller: _userSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search User',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              StreamBuilder<List<DocumentSnapshot>>(
                stream: firestoreReadService.getOrgMembersDocuments(
                    orgSelectorChangeNotifier.orgId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading users'));
                  }
                  final List<DocumentSnapshot> orgMemberDocs = snapshot.data ?? [];
                  final filteredDocs = orgMemberDocs.where((doc) {
                    final name = doc['orgMemberDisplayName']
                        .toString()
                        .toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredDocs.isNotEmpty) {
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: filteredDocs.map((orgMemberDoc) {
                            return ListTile(
                              title: Text(orgMemberDoc['orgMemberDisplayName']),
                              subtitle: Text(orgMemberDoc['orgMemberEmail']),
                              onTap: () {
                                widget.onUserSelected(orgMemberDoc.id);
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  } else {
                    return const Column(
                      children: [
                        SizedBox(height: 16),
                        Center(child: Text('No users found.')),
                      ],
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog (or add additional logic)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
        ),
      ],
    );
  }
}

