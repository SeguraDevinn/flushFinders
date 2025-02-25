import 'package:flutter/material.dart';
import 'placeholder_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_page.dart';
import 'finder.dart';
import 'banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    FinderPage(),
    ProfilePage(),
    const PlaceHolderWidget("Rewards Page"),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.square),
                label: "Finder",
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.square),
              //   label: "Rewards",
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.square),
                label: "Profile",
              ),
            ],
          ),
        ],
      ),
    );
  }
}