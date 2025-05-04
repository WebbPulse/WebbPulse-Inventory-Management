import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/styling/styling_widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VerkadaGroupWhitelistDialog extends StatefulWidget {
  final String orgId;
  final List<Map<String, dynamic>> initialGroups;

  const VerkadaGroupWhitelistDialog({
    super.key,
    required this.orgId,
    required this.initialGroups,
  });

  @override
  _VerkadaGroupWhitelistDialogState createState() =>
      _VerkadaGroupWhitelistDialogState();
}

class _VerkadaGroupWhitelistDialogState
    extends State<VerkadaGroupWhitelistDialog> {
  late Map<String, bool> _currentWhitelistStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize local state with initial whitelist status
    _currentWhitelistStatus = {
      for (var group in widget.initialGroups)
        (group['groupId'] as String? ?? ''):
            (group['isWhitelisted'] as bool? ?? false)
    };
    // Filter out entries with empty keys if any groupId was null/missing
    _currentWhitelistStatus.removeWhere((key, value) => key.isEmpty);
  }

  void _handleCheckboxChanged(String groupId, bool? newValue) {
    if (newValue != null) {
      setState(() {
        _currentWhitelistStatus[groupId] = newValue;
      });
    }
  }

  Future<void> _saveChanges() async {
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    // Prepare the data for the bulk update function
    // Ensure you only send valid group IDs
    final Map<String, bool> updatesToSend = Map.from(_currentWhitelistStatus)
      ..removeWhere((key, value) => key.isEmpty);

    if (updatesToSend.isEmpty && widget.initialGroups.isNotEmpty) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'No valid groups to update.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // *** IMPORTANT: Replace with your actual new bulk update function name ***
      await firebaseFunctions
          .httpsCallable('update_verkada_group_whitelists_callable')
          .call({
        'orgId': widget.orgId,
        'groupWhitelistStatus': updatesToSend, // Send the map of statuses
      });
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Group whitelist updated successfully');
      Navigator.of(context).pop(true); // Pop dialog and indicate success
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to update group whitelist: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Filter groups to only include those with a valid groupId for display
    final validGroups = widget.initialGroups
        .where((group) =>
            group['groupId'] != null && (group['groupId'] as String).isNotEmpty)
        .toList();

    return AlertDialog(
      title: const Text('Manage Verkada User Group Whitelisting'),
      content: SizedBox(
        width: double.maxFinite, // Use available width
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (validGroups.isEmpty
                ? const Center(
                    child: Text(
                        'No valid Verkada groups found. Have you synced your Verkada credentials?'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: validGroups.length,
                    itemBuilder: (context, index) {
                      final group = validGroups[index];
                      final String groupId = group['groupId']
                          as String; // Already checked non-null/empty
                      final String groupName =
                          group['groupName'] as String? ?? 'Unknown Group';
                      final bool isWhitelisted =
                          _currentWhitelistStatus[groupId] ?? false;

                      return CheckboxListTile(
                        title: Text(groupName),
                        value: isWhitelisted,
                        onChanged: (bool? newValue) =>
                            _handleCheckboxChanged(groupId, newValue),
                        secondary: const Icon(Icons.group),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  )),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading
              ? null
              : () =>
                  Navigator.of(context).pop(false), // Indicate no changes saved
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _saveChanges,
        ),
      ],
    );
  }
}
