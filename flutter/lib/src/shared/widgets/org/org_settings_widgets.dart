import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/styling/styling_widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';

// OrgNameEditor provides a text field to edit the organization's name.
class OrgNameEditor extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const OrgNameEditor({super.key, required this.orgData});

  @override
  _OrgNameEditorState createState() => _OrgNameEditorState();
}

class _OrgNameEditorState extends State<OrgNameEditor> {
  late TextEditingController orgNameController;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    orgNameController =
        TextEditingController(text: widget.orgData['orgName'] as String? ?? '');
  }

  @override
  void dispose() {
    orgNameController.dispose();
    super.dispose();
  }

  /// Handles the submission of the new organization name.
  void _onSubmit() async {
    final newName = orgNameController.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions.httpsCallable('update_org_name_callable').call({
        'orgId': widget.orgData['orgId'],
        'orgName': newName,
      });

      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Org name changed successfully');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to change Org name: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: orgNameController,
      decoration: InputDecoration(
        labelText: 'Organization Name',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.edit),
        suffixIcon: IconButton(
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.check),
          onPressed: _isLoading ? null : _onSubmit,
        ),
      ),
    );
  }
}

//
class OrgDeviceRegexEditor extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const OrgDeviceRegexEditor({super.key, required this.orgData});

  @override
  _OrgDeviceRegexEditorState createState() => _OrgDeviceRegexEditorState();
}

class _OrgDeviceRegexEditorState extends State<OrgDeviceRegexEditor> {
  late TextEditingController regexStringController;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    regexStringController = TextEditingController(
        text: widget.orgData['orgDeviceRegexString'] as String? ?? '');
  }

  @override
  void dispose() {
    regexStringController.dispose();
    super.dispose();
  }

  /// Handles the submission of the new organization name.
  void _onSubmit() async {
    final newRegexString = regexStringController.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions
          .httpsCallable('update_org_device_regex_callable')
          .call({
        'orgId': widget.orgData['orgId'],
        'orgDeviceRegexString': newRegexString,
      });

      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Device regex configuration changed');
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to change device regex configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: regexStringController,
      decoration: InputDecoration(
        labelText: 'Device Regex Filter',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.edit),
        suffixIcon: IconButton(
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.check),
          onPressed: _isLoading ? null : _onSubmit,
        ),
      ),
    );
  }
}

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
  const VerkadaCredentialsEditor({super.key, required this.orgData});

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
    verkadaOrgShortNameController = TextEditingController(
        text: widget.orgData['orgVerkadaOrgShortName'] as String? ?? '');
    verkadaOrgEmailController = TextEditingController(
        text: widget.orgData['orgVerkadaBotEmail'] as String? ?? '');
    verkadaOrgPasswordController = TextEditingController(
        text: widget.orgData['orgVerkadaBotPassword'] as String? ?? '');
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
    final orgId = widget.orgData['orgId'];

    if (orgId == null ||
        shortName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Please fill all Verkada credential fields.');
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

class OrgImageEditorAlertDialog extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const OrgImageEditorAlertDialog({super.key, required this.orgData});

  @override
  OrgImageEditorAlertDialogState createState() =>
      OrgImageEditorAlertDialogState();
}

class OrgImageEditorAlertDialogState extends State<OrgImageEditorAlertDialog> {
  late TextEditingController urlController;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController();
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final newOrgImageUrl = urlController.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions
          .httpsCallable('update_org_background_image_callable')
          .call({
        'orgId': widget.orgData['orgId'],
        'orgBackgroundImageURL': newOrgImageUrl,
      });

      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Org background image changed successfully');
      AsyncContextHelpers.popContextIfMounted(context);
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to change Org background image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Change Organization Image URL'),
      content: SizedBox(
        height: 120,
        child: Column(
          children: [
            const Text(
              'Please enter the URL of the new image for the organization background:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          onPressed: _isLoading ? null : _onSubmit,
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.photo),
          label: const Text('Change Organization Image'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
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

/// DeleteOrgAlertDialog confirms and handles the deletion of the organization.
class DeleteOrgAlertDialog extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const DeleteOrgAlertDialog({super.key, required this.orgData});

  @override
  DeleteOrgAlertDialogState createState() => DeleteOrgAlertDialogState();
}

class DeleteOrgAlertDialogState extends State<DeleteOrgAlertDialog> {
  var _isLoading = false;

  void _onSubmit() async {
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    final authenticationChangeNotifier =
        Provider.of<AuthenticationChangeNotifier>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions.httpsCallable('delete_org_callable').call({
        'orgId': widget.orgData['orgId'],
      });
      authenticationChangeNotifier.signOutUser();
    } catch (e) {
      await AsyncContextHelpers.showSnackBarIfMounted(
          context, 'Failed to delete Org: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Delete Organization'),
      content: const Text(
          'Are you sure you want to delete this organization? This action cannot be undone.'),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onSubmit,
          icon: _isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.delete),
          label: const Text('Delete Organization'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.all(16.0),
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
        ),
      ],
    );
  }
}
