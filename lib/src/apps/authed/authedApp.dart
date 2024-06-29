import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/authenticationProvider.dart';

import '../../services/firestoreService.dart';
import 'authedUserExistsApp.dart';

class AuthedApp extends StatelessWidget {
  final FirestoreService firestoreService;

  const AuthedApp({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return StreamBuilder<bool>(
            stream: firestoreService
                .checkUserExistsInFirestoreStream(authProvider.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error checking user exists');
              } else if (snapshot.data == false) {
                return FutureBuilder<void>(
                    future: firestoreService.createUser(authProvider.uid,
                        authProvider.email, authProvider.displayName),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error creating user');
                      }
                      return AuthedUserExistsApp(
                        firestoreService: firestoreService,
                      );
                    });
              }
              return AuthedUserExistsApp(
                firestoreService: firestoreService,
              );
            });
      },
    );
  }
}
