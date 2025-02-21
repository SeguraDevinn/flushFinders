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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _reportProblem(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report Problem Selected")),
    );
  }

  void _showHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Help selected")),
    );
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final userRef = _firestore.collection('Users').doc(userId);
      final reviewsSnapshot = await userRef.collection('reviews').get();

      List<Map<String, dynamic>> reviews = [];
      for (var doc in reviewsSnapshot.docs) {
        reviews.add(doc.data());
      }

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Flush Finders"),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (String value) {
                if (value == 'Sign Out') {
                  _logout(context);
                } else if (value == 'Report a Problem') {
                  _reportProblem(context);
                } else if (value == 'Help') {
                  _showHelp(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Report a Problem',
                  child: Text('Report a Problem'),
                ),
                const PopupMenuItem<String>(
                  value: 'Help',
                  child: Text('Help'),
                ),
                const PopupMenuItem<String>(
                  value: 'Sign Out',
                  child: Text('Sign Out'),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Info"),
              Tab(text: "Reviews"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: User Information
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('Users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error fetching user data: ${snapshot.error}');
                  return const Center(child: Text("Error loading data"));
                }

                if (snapshot.hasData && snapshot.data!.exists) {
                  var userData = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blueGrey,
                          child: const Icon(Icons.person, size: 60, color: Colors.white),
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
                        const SizedBox(height: 20),
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

                debugPrint('User data not found for UID: ${user.uid}');
                return const Center(child: Text("No user data available"));
              },
            ),

            // Tab 2: User Reviews
            FutureBuilder<List<Map<String, dynamic>>>(
              future: getUserReviews(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error fetching reviews: ${snapshot.error}');
                  return const Center(child: Text("Error loading reviews"));
                }

                if (snapshot.hasData) {
                  final reviews = snapshot.data!;
                  if (reviews.isEmpty) {
                    return const Center(
                      child: Text(
                        "no reviews",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // If there are reviews, show them in a scrollable ListView
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                        child: ListTile(
                          title: Text(review['title'] ?? 'Review'),
                          subtitle: Text(review['content'] ?? ''),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text("No reviews"));
              },
            ),
          ],
        ),
      ),
    );
  }
}
