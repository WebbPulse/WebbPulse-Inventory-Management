import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../home_view.dart';
import '../../services/firestoreService.dart';

class SignInView extends StatelessWidget {
  SignInView({super.key, required this.firestoreService});

  static const routeName = '/signin';

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) async {
          final user = state.user;
          final uid = user?.uid;
          final email = user?.email;

          if (uid == null) {
            print('UID is null');
            return;
          }

          try {
            bool userExists =
                await firestoreService.checkUserExistsInFirestore(uid);
            if (!userExists) {
              await firestoreService.createUserInFirestore(uid, email);
            }

            // Navigate after Firestore operations are complete
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          } catch (e) {
            print('Error during sign-in: $e');
          }
        }),
      ],
    );
  }
}
