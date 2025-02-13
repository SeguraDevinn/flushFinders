import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  const ProfilePage({super.key});

  void _logout(BuildContext context) async {
    await _auth.signOut();
    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final userRef = _firestore.collection('Users').doc(userId);
      final reviewsSnapshot = await userRef.collection('reviews').get();

      List<Map<String, dynamic>> reviews = [];
      reviewsSnapshot.docs.forEach((doc) {
        reviews.add(doc.data());
      });

      return reviews;
    } catch (e) {
      print("Error retrieving user reviews: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flush Finders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('Users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching user data: ${snapshot.error}');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  // Username
                  Text(
                    userData['username'] ?? 'No username',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Flush Finder Since: ${(userData['dateCreated'] as Timestamp).toDate().toLocal().month} ${(userData['dateCreated'] as Timestamp).toDate().year}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Stats",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Review Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "# of Reviews:",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${userData['reviewCount'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Premium Banner
                  Column(
                    children: [
                      const Text(
                        "Flush Finders Free",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle premium upgrade
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Upgrade to Premium"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Fallback if no data exists
          debugPrint('User data not found for UID: ${user.uid}');
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
