import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/authenticationProvider.dart';
import '../../providers/orgSelectorProvider.dart';

import '../../services/firestoreService.dart';
import 'authedOrgSelectedApp.dart';

class AuthedApp extends StatelessWidget {
  final FirestoreService firestoreService;

  AuthedApp({
    Key? key,
    required this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return FutureBuilder<bool>(
            future:
                firestoreService.checkUserExistsInFirestore(authProvider.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error checking user exists');
              } else if (snapshot.data == false) {
                firestoreService.createUserInFirestore(
                    authProvider.uid, authProvider.email);
              }
              return StreamBuilder<List<String>>(
                stream: firestoreService.organizationsStream(authProvider.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error loading organizations');
                  }
                  final organizationUids = snapshot.data ?? [];
                  return ChangeNotifierProvider(
                    create: (_) => OrgSelectorProvider(),
                    child: AuthedOrgSelectedApp(
                      firestoreService: firestoreService,
                      organizationUids: organizationUids,
                    ),
                  );
                },
              );
            });
      },
    );
  }
}
