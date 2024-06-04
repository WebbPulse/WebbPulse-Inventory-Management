import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../organization_home_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  static const routeName = '/signin';
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      User? user = await _authService.signInWithEmail(_email, _password);
      if (user != null) {
        // Navigate to the organization home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrganizationHomeScreen(orgId: user.uid)), // Adjust based on how you identify the organization
        );
      } else {
        // Handle sign-in failure (e.g., show an error message)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sign-In failed. Please try again.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _signIn,
                    child: Text('Sign In'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, ForgotPasswordPage.routeName);
                    },
                    child: Text('Forgot Password?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
