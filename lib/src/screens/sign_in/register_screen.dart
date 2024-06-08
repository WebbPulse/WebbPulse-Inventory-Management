import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../providers/authentication_state.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: ElevatedButton(
          onPressed: () {
            if (authState.loggedIn) {
              FirestoreService.createOrganization('My Organization', authState.uid!);
            }   
            else {
            // Handle not logged in state
            }
          },
          child: const Text('Register'),
        )
    );
  }
}