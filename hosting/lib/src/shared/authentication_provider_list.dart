import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// Google OAuth provider
// Apple OAuth provider

List<AuthProvider> authenticationProviderList = [
  EmailAuthProvider(), // Enable email/password sign-in
  ///GoogleProvider(
      ///clientId:
          ///'1096617861007-ek22rdfust1c288m6cl2fq8649i7albp.apps.googleusercontent.com'), // Enable Google sign-in and supply required client ID
];


/// apple provider removed for now
/// same with google sign on
/// both will need to be added at the same time to make apple not be mad