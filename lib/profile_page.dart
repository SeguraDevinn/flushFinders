import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flush Finders"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 50,),
          ),
          const SizedBox(height: 10),
          const Text(
            "McFlyster_123",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text("Flush Finder Since Nov. 2024"),
          const SizedBox(height: 20),
          Container(
            color: Colors.blue[200],
            padding: const EdgeInsets.all(10),
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 20),
                    Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 20),
                    Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Reset password'),
                const Text('Update billing info'),
                const Text('Contact Us'),
                const SizedBox (height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow),
                    child: const Text(
                      "Upgrade to premium",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}