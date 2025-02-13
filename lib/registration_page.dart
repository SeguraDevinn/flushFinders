import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpassword = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {

        bool usernameExisits = await _checkUsernameExists(_username.text.trim());
        if (usernameExisits) {
          _showSnackBar('Username already in use. Please choose another.');
          return;
        }
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        //get the user name
        User? user = userCredential.user;

        if (user != null) {
          // Adding user to firestore
          await _addUserToFirestore(user);
        }

        _showSnackBar('Resgistration successful!');


        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen()),
                (route) => false
        );
      } on FirebaseAuthException catch(e) {
        _handleAuthError(e);
      }
    }
  }

  Future<void> _addUserToFirestore(User user) async {
    //sets the user in 'Users' and inserts using information provided
    await _firestore.collection('Users').doc(user.uid).set({
      'username': _username.text.trim(),
      'email': _emailController.text.trim(),
      'dateCreated': FieldValue.serverTimestamp(),
      'reviewCount': 0,
    });

    //initialize the users subcollection 'reviews'
    await _firestore.collection('Users').doc(user.uid).collection('reviews').doc('initialDoc').set({
      //init as empty since no reviews yet
      'intial' : true,
    });
  }


  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('Users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      default:
        message = 'An error occurred. Please try again.';
    }
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black54),
    );
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Register')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Username Field
            TextFormField(
              controller: _username,
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            //Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter your email' : null,
            ),
            SizedBox(height: 16),
            //Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                } else if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            //Confirm password Field
            TextFormField(
              controller: _confirmpassword,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
