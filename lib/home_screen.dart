import 'package:flutter/material.dart';
import 'placeholder_widget.dart';
import 'profile_page.dart';
import 'location_helpers/location_request.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_radar/flutter_radar.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
  const PlaceHolderWidget("Rewards Page"),
    const PlaceHolderWidget("Rewards Page"),
    ProfilePage(),
  ];



  @override
  void initState() {
    super.initState();
    LocationHandler.checkAndRequestPermissions();
    Radar.startTracking('continuous');
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus isPermissionGranted = await Permission.location.request();
    if (isPermissionGranted.isGranted) {
      print("Location is enabled");
    } else {
      print("Location is not enabled");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.square),
            label: "Finder",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.square),
            label: "Rewards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.square),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
