import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import 'package:webbcheck/src/shared/providers/authentication_change_notifier.dart';
import 'package:webbcheck/src/shared/providers/firestore_read_service.dart';
import 'package:webbcheck/src/shared/widgets.dart';
import 'package:webbcheck/src/shared/helpers/async_context_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsView extends StatelessWidget {
  const ProfileSettingsView({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return Consumer3<FirebaseFunctions, AuthenticationChangeNotifier,
            FirestoreReadService>(
        builder: (context, firebaseFunctions, authenticationChangeNotifier,
            firestoreService, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        drawer: const AuthedDrawer(),
        body: StreamBuilder<DocumentSnapshot>(
            stream: firestoreService
                .getGlobalUserDocument(authenticationChangeNotifier.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading user data'));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('User not found'));
              }
              final DocumentSnapshot userDocument = snapshot.data!;
              final bool hasPhoto = userDocument['userPhotoURL'] != '';

              return ProfileScreen(
                avatar: hasPhoto
                    ? CircleAvatar(
                        radius: 75,
                        backgroundImage:
                            NetworkImage(userDocument['userPhotoURL']),
                      )
                    : null,
                actions: [
                  DisplayNameChangedAction(
                    (context, user, userDisplayName) async {
                      await firebaseFunctions
                          .httpsCallable(
                              'update_global_user_display_name_callable')
                          .call(
                        {
                          'userDisplayName': userDisplayName,
                        },
                      );
                    },
                  ),
                  SignedOutAction((context) {
                    authenticationChangeNotifier.setUserWasLoggedIn(false);
                  }),
                ],
                providers: [
                  EmailAuthProvider(),
                ],
                children: [
                  const SizedBox(height: 16),
                  ElevatedButton(
                      child: const Text('Change Profile Picture'),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const ChangeProfilePictureAlertDialog();
                            });
                      }),
                ],
              );
            }),
      );
    });
  }
}

class ChangeProfilePictureAlertDialog extends StatefulWidget {
  const ChangeProfilePictureAlertDialog({super.key});

  @override
  ChangeProfilePictureAlertDialogState createState() =>
      ChangeProfilePictureAlertDialogState();
}

class ChangeProfilePictureAlertDialogState
    extends State<ChangeProfilePictureAlertDialog> {
  late TextEditingController _userPhotoURLController;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userPhotoURLController = TextEditingController();
  }

  @override
  void dispose() {
    _userPhotoURLController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final userPhotoURL = _userPhotoURLController.text;
    final firebaseFunctions =
        Provider.of<FirebaseFunctions>(context, listen: false);
    if (userPhotoURL.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await firebaseFunctions
            .httpsCallable('update_global_user_photo_url_callable')
            .call(
          {
            'userPhotoURL': userPhotoURL,
          },
        );

        /// insert async function here
        AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Profile picture changed successfully');
        AsyncContextHelpers.popContextIfMounted(context);
      } catch (e) {
        await AsyncContextHelpers.showSnackBarIfMounted(
            context, 'Failed to change profile picture: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Profile Picture'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the URL of a picture to use as your profile '
                  'picture.'),
              const SizedBox(height: 16.0),
              TextField(
                controller: _userPhotoURLController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onSubmit,
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
              icon: _isLoading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.photo),
              label: const Text('Change Profile Picture'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ],
    );
  }
}