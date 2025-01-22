import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_helpers/firebase_options.dart';
import 'home_screen.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase with options
  );

  await dotenv.load();
  //initialize Radar
  String radarApiKey = dotenv.env['RADAR_API_KEY'] ?? '';
  Radar.initialize(radarApiKey);
  setUserID();
  runApp(const MyApp());
}

void setUserID() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String userId = user.uid;
    Radar.setUserId(userId);
  } else {
    print("User id not found");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase App',
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return LoginPage();
        }
      },
    );
  }
}





