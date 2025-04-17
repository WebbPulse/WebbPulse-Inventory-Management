import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/authentication_change_notifier.dart';

import 'package:webbpulse_inventory_management/src/shared/providers/firestore_read_service.dart';
import 'package:webbpulse_inventory_management/src/shared/providers/org_selector_change_notifier.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/users/user_widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/org/org_widgets.dart';
import 'package:webbpulse_inventory_management/src/shared/widgets/org/org_settings_widgets.dart';

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
                                      VerkadaIntegrationToggle(
                                        orgDocument: orgDocument,
                                      ),
                                      const SizedBox(height: 16),
                                      if (orgDocument['verkadaIntegrationEnabled'] == true) ...[
                                        const Text(
                                          'Verkada Org Integration Settings',
                                          style: TextStyle(
                                            fontSize: 20,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        VerkadaOrgShortNameEditor(
                                          orgDocument: orgDocument,
                                        ),
                                        const SizedBox(height: 16),
                                        VerkadaOrgEmailEditor(
                                          orgDocument: orgDocument,
                                        ),
                                        const SizedBox(height: 16),
                                        VerkadaOrgPasswordEditor(
                                          orgDocument: orgDocument,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
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


