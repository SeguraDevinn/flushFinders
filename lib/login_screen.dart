import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registration_page.dart';
import 'home_screen.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
   _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //firebase auth instance initialization
  final FirebaseAuth _auth = FirebaseAuth.instance;


  //Login Function
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen()),
                (route) => false
        );
      } on FirebaseAuthException catch (e) {
        String message;
        // Error handling
        switch (e.code) {
          case 'invalid-email':
            message = 'The email address is not valid.';
            break;
          case 'user-disabled':
            message = 'This user account has been disabled.';
            break;
          case 'user-not-found':
            message = 'No user found with this email.';
            break;
          case 'wrong-password':
            message = 'Incorrect password. Please try again.';
            break;
          case 'weak-password':
            message = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            message = 'An account already exists with this email.';
            break;
          default:
            message = 'An unknown error occurred. Please try again.';
        }

        // Show a SnackBar with the custom error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.black54,
          ),
        );
      } catch (e) {
        // Handle any other errors that might occur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.black54,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (password) {
                  if (password == null || password.isEmpty) {
                    return 'Password is required';
                  } else if (password.length < 8) {
                    return "Password must be at least 8 characters long.";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Login Button
              ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
              ),

              SizedBox(height: 16.0),

              // Divider
              Divider(thickness: 1, color: Colors.grey[400]),

              // Apple sign in Placeholder
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Sign in with Apple
                },
                icon: Icon(Icons.apple, color: Colors.white),
                label: Text('Sign in with Apple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
              SizedBox(height: 8.0),

              // Google sign in Placeholder
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Sign in with Google
                },
                icon: Icon(Icons.g_mobiledata, color: Colors.white),
                label: Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed:() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child: Text("Don't have an account? Create one here!"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
