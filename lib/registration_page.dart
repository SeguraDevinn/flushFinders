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
        bool usernameExists = await _checkUsernameExists(_username.text.trim());
        if (usernameExists) {
          _showSnackBar('Username already in use. Please choose another.');
          return;
        }
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          // Add user to Firestore along with the username.
          await _addUserToFirestore(user);
        }

        _showSnackBar('Registration successful!');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        _handleAuthError(e);
      }
    }
  }

  Future<bool> _checkUsernameExists(String username) async {
    DocumentSnapshot doc = await _firestore.collection('usernames').doc(username).get();
    return doc.exists;
  }

  Future<void> _addUserToFirestore(User user) async {
    WriteBatch batch = _firestore.batch();

    // References for user and username documents.
    DocumentReference userRef = _firestore.collection('Users').doc(user.uid);
    DocumentReference usernameRef = _firestore.collection('usernames').doc(_username.text.trim());

    // Set the user document.
    batch.set(userRef, {
      'username': _username.text.trim(),
      'email': _emailController.text.trim(),
      'dateCreated': FieldValue.serverTimestamp(),
      'reviewCount': 0,
    });

    // Set the username document.
    batch.set(usernameRef, {
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Initialize the reviews subcollection for the user.
    DocumentReference initialReviewRef = userRef.collection('reviews').doc('initialDoc');


    // Commit both writes atomically.
    await batch.commit();
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
              // Username Field
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
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
              SizedBox(height: 16),
              // Password Field
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
              // Confirm Password Field
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
