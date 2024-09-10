import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/shared/helpers/async_context_helpers.dart';

import '../../../../shared/providers/firestore_read_service.dart';
import '../../../../shared/providers/org_selector_change_notifier.dart';
import '../../../../shared/widgets.dart';

class OrgSettingsView extends StatelessWidget {
  const OrgSettingsView({super.key});
  static const routeName = '/org-settings';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OrgDocumentStreamBuilder(builder: (context, orgDocument) {
      return Scaffold(
        appBar: const OrgNameAppBar(
          titleSuffix: 'Settings',
        ),
        drawer: const AuthedDrawer(),
        body: Stack(
          children: [
            if (orgDocument['orgBackgroundImageURL'] != null &&
                orgDocument['orgBackgroundImageURL'] != '')
              Positioned.fill(
                child: Image.network(
                  orgDocument['orgBackgroundImageURL'],
                  fit: BoxFit.cover,
                ),
              ),
            SafeArea(
              child: SizedBox.expand(
                child: Consumer4<
                    OrgSelectorChangeNotifier,
                    FirestoreReadService,
                    AuthenticationChangeNotifier,
                    FirebaseFunctions>(
                  builder: (context, orgSelectorProvider, firestoreService,
                      authenticationChangeNotifier, firebaseFunctions, child) {
                    return SingleChildScrollView(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Set maximum width constraints based on screen size
                            double maxWidth;
                            if (constraints.maxWidth < 600) {
                              maxWidth = constraints.maxWidth * 0.95;
                            } else if (constraints.maxWidth < 1200) {
                              maxWidth = constraints.maxWidth * 0.6;
                            } else {
                              maxWidth = constraints.maxWidth * 0.4;
                            }

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxWidth,
                              ),
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Organization Settings',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      OrgNameEditor(
                                        orgDocument: orgDocument,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return OrgImageEditorAlertDialog(
                                                  orgDocument: orgDocument,
                                                );
                                              });
                                        },
                                        icon: const Icon(Icons.image),
                                        label: const Text(
                                            'Change Organization Image'),
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
                                      ),
                                      const SizedBox(height: 20),
                                      // Delete Org Button with Distinct Color
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return DeleteOrgAlertDialog(
                                                  orgDocument: orgDocument,
                                                );
                                              });
                                        },
                                        icon: const Icon(Icons.delete),
                                        label:
                                            const Text('Delete Organization'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.all(16.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class OrgNameEditor extends StatefulWidget {
  final dynamic orgDocument;

  const OrgNameEditor({super.key, required this.orgDocument});

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
        TextEditingController(text: widget.orgDocument['orgName'] as String);
  }

  @override
  void dispose() {
    orgNameController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final newName = orgNameController.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseFunctions.httpsCallable('update_org_name_callable').call({
        'orgId': widget.orgDocument.id,
        'orgName': newName,
      });

      /// insert async function here
      AsyncContextHelpers.showSnackBarIfMounted(
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

class OrgImageEditorAlertDialog extends StatefulWidget {
  final dynamic orgDocument;

  const OrgImageEditorAlertDialog({super.key, required this.orgDocument});

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
        'orgId': widget.orgDocument.id,
        'orgBackgroundImageURL': newOrgImageUrl,
      });

      /// insert async function here
      AsyncContextHelpers.showSnackBarIfMounted(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
            const SizedBox(height: 16.0),
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
            
            
          ],
        ),
      ],
    );
  }
}

class DeleteOrgAlertDialog extends StatefulWidget {
  final dynamic orgDocument;

  const DeleteOrgAlertDialog({super.key, required this.orgDocument});

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
        'orgId': widget.orgDocument.id,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
            const SizedBox(height: 16.0),
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
            
            
          ],
        ),
      ],
    );
  }
}
