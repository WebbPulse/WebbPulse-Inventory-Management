import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/styling/styling_widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/org/org_settings_widgets/verkada_integration_settings/whitelisting/user_group_whitelisting.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/org/org_settings_widgets/verkada_integration_settings/whitelisting/product_site_linking.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VerkadaIntegrationToggle extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const VerkadaIntegrationToggle({super.key, required this.orgData});

  @override
  _VerkadaIntegrationToggleState createState() =>
      _VerkadaIntegrationToggleState();
}

class _VerkadaIntegrationToggleState extends State<VerkadaIntegrationToggle> {
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _onToggleChanged(bool newValue) async {
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseFunctions
          .httpsCallable('update_verkada_integration_status_callable')
          .call({
        'orgId': widget.orgData['orgId'],
        'enabled': newValue,
      });

      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Verkada integration status updated successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to update Verkada integration status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEnabledState =
        widget.orgData['orgVerkadaIntegrationEnabled'] as bool? ?? false;

    return SwitchListTile(
      title: const Text('Verkada Command Integration'),
      value: currentEnabledState,
      onChanged: _isLoading ? null : _onToggleChanged,
      secondary: _isLoading
          ? const CircularProgressIndicator()
          : const Icon(Icons.integration_instructions),
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

// Combined widget for Verkada Credentials
class VerkadaCredentialsEditor extends StatefulWidget {
  final Map<String, dynamic> orgData;
  final Map<String, dynamic>? orgVerkadaIntegrationData;
  const VerkadaCredentialsEditor(
      {super.key,
      required this.orgData,
      required this.orgVerkadaIntegrationData});

  @override
  _VerkadaCredentialsEditorState createState() =>
      _VerkadaCredentialsEditorState();
}

class _VerkadaCredentialsEditorState extends State<VerkadaCredentialsEditor> {
  late TextEditingController verkadaOrgShortNameController;
  late TextEditingController verkadaOrgEmailController;
  late TextEditingController verkadaOrgPasswordController;
  var _isLoading = false;
  bool _obscureText = true;
  @override
  void initState() {
    super.initState();
    // Use null-aware access on the potentially null map
    verkadaOrgShortNameController = TextEditingController(
        text: widget.orgVerkadaIntegrationData?['orgVerkadaOrgShortName']
                as String? ??
            '');
    verkadaOrgEmailController = TextEditingController(
        text: widget.orgVerkadaIntegrationData?['orgVerkadaBotEmail']
                as String? ??
            '');
    verkadaOrgPasswordController = TextEditingController(
        text: widget.orgVerkadaIntegrationData?['orgVerkadaBotPassword']
                as String? ??
            '');
  }

  @override
  void dispose() {
    verkadaOrgShortNameController.dispose();
    verkadaOrgEmailController.dispose();
    verkadaOrgPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final shortName = verkadaOrgShortNameController.text;
    final email = verkadaOrgEmailController.text;
    final password = verkadaOrgPasswordController.text;
    // Add null check for orgId access
    final orgId = widget.orgData['orgId'] as String?;

    if (orgId == null ||
        shortName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context,
          orgId == null
              ? 'Organization ID is missing.' // Specific message if orgId is null
              : 'Please fill all Verkada credential fields.');
      return;
    }

    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions
          .httpsCallable('sync_verkada_permissions_callable')
          .call({
        'orgId': orgId,
        'orgVerkadaOrgShortName': shortName,
        'orgVerkadaBotEmail': email,
        'orgVerkadaBotPassword': password,
      });

      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Verkada credentials synced successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to sync Verkada credentials: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: verkadaOrgShortNameController,
          decoration: const InputDecoration(
            labelText: 'Verkada Org Short Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: verkadaOrgEmailController,
          decoration: const InputDecoration(
            labelText: 'Verkada Bot Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16.0),
        TextField(
          obscureText: _obscureText,
          controller: verkadaOrgPasswordController,
          decoration: InputDecoration(
            labelText: 'Verkada Bot Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmit,
          icon: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Icon(Icons.sync),
          label: const Text('Sync Verkada Credentials'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.all(16.0),
          ),
        ),
      ],
    );
  }
}

// Combined widget for Verkada Settings after Auth
class VerkadaSettingsEditor extends StatefulWidget {
  final Map<String, dynamic> orgData;
  final Map<String, dynamic>? orgVerkadaIntegrationData;
  const VerkadaSettingsEditor(
      {super.key,
      required this.orgData,
      required this.orgVerkadaIntegrationData});

  @override
  _VerkadaSettingsEditorState createState() => _VerkadaSettingsEditorState();
}

class _VerkadaSettingsEditorState extends State<VerkadaSettingsEditor> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showUserWhitelistDialog(BuildContext context, String orgId,
      List<Map<String, dynamic>> currentGroups) {
    showDialog<bool>(
      // Expect a boolean result
      context: context,
      builder: (BuildContext dialogContext) {
        return VerkadaGroupWhitelistDialog(
          orgId: orgId,
          initialGroups: currentGroups,
        );
      },
    ).then((saved) {
      if (saved == true) {}
    });
  }

  void _showProductSiteDesignationDialog(BuildContext context, String orgId,
      Map<String, dynamic> verkadaProductSiteDesignations) {
    showDialog<bool>(
      // Expect a boolean result
      context: context,
      builder: (BuildContext dialogContext) {
        return VerkadaProductSiteDesignationDialog(
          orgId: orgId,
          verkadaProductSiteDesignations: verkadaProductSiteDesignations,
        );
      },
    ).then((saved) {
      if (saved == true) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgId = widget.orgData['orgId'] as String;

    final List<Map<String, dynamic>> verkadaUserGroups =
        (widget.orgVerkadaIntegrationData?['orgVerkadaUserGroups'] as List?)
                ?.map((item) {
                  if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  }
                  return null;
                })
                .whereType<Map<String, dynamic>>()
                .toList() ??
            [];
    final Map<String, dynamic> verkadaProductSiteDesignations =
        (widget.orgVerkadaIntegrationData?['orgVerkadaProductSiteDesignations']
                as Map<String, dynamic>?) ??
            {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Verkada Product Designated Sites',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        if (widget.orgVerkadaIntegrationData == null)
          const Text(
              'Verkada credentials not synced. Sync credentials to manage groups.')
        else
          ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Manage Verkada Sites'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.all(16.0),
              ),
              onPressed: () {
                _showProductSiteDesignationDialog(
                    context, orgId, verkadaProductSiteDesignations);
              }),
        const SizedBox(height: 16.0),
        const Text('Verkada User Group Whitelist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        if (widget.orgVerkadaIntegrationData == null)
          const Text(
              'Verkada credentials not synced. Sync credentials to manage groups.')
        else
          ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Manage Verkada User Groups'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.all(16.0),
              ),
              onPressed: () {
                _showUserWhitelistDialog(context, orgId, verkadaUserGroups);
              }),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
