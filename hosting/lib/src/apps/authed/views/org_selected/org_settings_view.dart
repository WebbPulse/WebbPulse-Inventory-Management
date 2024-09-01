import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/apps/authed/views/org_selection_view.dart';

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
                child:
                    Consumer2<OrgSelectorChangeNotifier, FirestoreReadService>(
                  builder:
                      (context, orgSelectorProvider, firestoreService, child) {
                    // Assuming you get the organization name from your provider
                    final currentOrgName = orgDocument['orgName'] as String;
                    final TextEditingController _controller =
                        TextEditingController(text: currentOrgName);

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Set maximum width constraints based on screen size
                              double maxWidth;
                              if (constraints.maxWidth < 600) {
                                maxWidth = constraints.maxWidth * 0.9;
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
                                          'Org Settings',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 40),
                                        // Change Org Name TextField with Submit Button
                                        TextField(
                                          controller: _controller,
                                          decoration: InputDecoration(
                                            labelText: 'Organization Name',
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.edit),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.check),
                                              onPressed: () {
                                                // Trigger logic to submit the new organization name
                                                final newName =
                                                    _controller.text;
                                                if (newName.isNotEmpty) {
                                                  final firebaseFunctions =
                                                      Provider.of<
                                                              FirebaseFunctions>(
                                                          context,
                                                          listen: false);
                                                  firebaseFunctions
                                                      .httpsCallable(
                                                          'update_org_name_callable')
                                                      .call({
                                                    'orgId': orgDocument.id,
                                                    'orgName': newName,
                                                  });
                                                }
                                                print(
                                                    'New Organization Name: $newName');
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Change Org Image Button with Border
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                final TextEditingController
                                                    _urlController =
                                                    TextEditingController();

                                                return AlertDialog(
                                                  title: const Text(
                                                      'Change Organization Image URL'),
                                                  content: TextField(
                                                    controller: _urlController,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Image URL',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: theme
                                                            .colorScheme.surface
                                                            .withOpacity(0.95),
                                                        side: BorderSide(
                                                          color: theme
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.5),
                                                          width: 1.5,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                      ),
                                                      onPressed: () async {
                                                        final firebaseFunctions =
                                                            Provider.of<
                                                                    FirebaseFunctions>(
                                                                context,
                                                                listen: false);
                                                        final newImageUrl =
                                                            _urlController.text;
                                                        if (newImageUrl
                                                            .isNotEmpty) {
                                                          firebaseFunctions
                                                              .httpsCallable(
                                                                  'update_org_background_image_callable')
                                                              .call({
                                                            'orgId':
                                                                orgDocument.id,
                                                            'orgBackgroundImageURL':
                                                                newImageUrl,
                                                          });
                                                          // After updating, you can pop the dialog
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                      child:
                                                          const Text('Update'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
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
                                            final firebaseFunctions =
                                                Provider.of<FirebaseFunctions>(
                                                    context,
                                                    listen: false);
                                            firebaseFunctions
                                                .httpsCallable(
                                                    'delete_org_callable')
                                                .call({
                                              'orgId': orgDocument.id,
                                            });
                                            Navigator.pushNamed(context,
                                                OrgSelectionView.routeName);
                                          },
                                          icon: const Icon(Icons.delete),
                                          label:
                                              const Text('Delete Organization'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
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
