import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'finder.dart';

class ReviewPage extends StatefulWidget {
  final int restroomId; // ID of the restroom being reviewed
  final String restroomName; // Name of the restroom

  ReviewPage({required this.restroomId, required this.restroomName});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Added semicolon here

  double? _rating;
  List<String> _selectedPros = [];
  List<String> _selectedCons = [];
  String _comment = "";

  final List<String> prosList = [
    "Toilet Paper",
    "Wax Paper",
    "Clean",
    "Soap",
    "Hand Dryer"
  ];
  final List<String> consList = [
    "No Toilet Paper",
    "Dirty",
    "Crowded",
    "No Soap",
    "No Hand Dryer"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review ${widget.restroomName}"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back when pressed
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating
              Text("Rating", style: TextStyle(fontSize: 18)),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < (_rating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              SizedBox(height: 16),

              // Pros Checkboxes
              Text("Pros", style: TextStyle(fontSize: 18)),
              Wrap(
                children: prosList.map((item) {
                  return FilterChip(
                    label: Text(item),
                    selected: _selectedPros.contains(item),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedPros.add(item);
                        } else {
                          _selectedPros.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Cons Checkboxes
              Text("Cons", style: TextStyle(fontSize: 18)),
              Wrap(
                children: consList.map((item) {
                  return FilterChip(
                    label: Text(item),
                    selected: _selectedCons.contains(item),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCons.add(item);
                        } else {
                          _selectedCons.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Comment TextBox
              Text("Comment (optional)", style: TextStyle(fontSize: 18)),
              TextField(
                onChanged: (text) {
                  _comment = text;
                },
                decoration: InputDecoration(
                  hintText: "Write your review here...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_rating != null) {
                    await submitReview();

                    // Show a confirmation message.
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Review submitted successfully!"))
                    );

                    // Optionally, wait a couple of seconds for the user to read the message.
                    await Future.delayed(Duration(seconds: 1));

                    // Navigate back to the map page.
                    // If your map page is already in the navigation stack, you could use Navigator.pop(context);
                    // Or, if you want to push a new route, use Navigator.pushReplacement.
                    Navigator.pop(context);
                  } else {
                    // If no rating is provided, prompt the user.
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please provide a rating'))
                    );
                  }
                },
                child: Text("Submit Review"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> submitReview() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('You need to be logged in to submit a review')),
        );
        return;
      }
      final String userID = user.uid;
      final String restroomDocId = widget.restroomId.toString();

      // Generate a new review ID.
      final String reviewId = _firestore
          .collection('Users')
          .doc(userID)
          .collection('reviews')
          .doc()
          .id;

      final reviewData = {
        'restroomId': widget.restroomId, // or use restroomDocId if you prefer
        'rating': _rating,
        'pros': _selectedPros,
        'cons': _selectedCons,
        'comment': _comment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Store the review in the user's subcollection.
      await _firestore
          .collection('Users')
          .doc(userID)
          .collection('reviews')
          .doc(reviewId)
          .set(reviewData);

      // Store the review in the restrooms subcollection.
      await _firestore
          .collection('restrooms')
          .doc(restroomDocId)
          .collection('reviews')
          .doc(reviewId)
          .set({
        ...reviewData,
        'userId': userID,
      });

      // Increment the review count for the user.
      await _firestore.collection('Users').doc(userID).update({
        'reviewCount': FieldValue.increment(1),
      });

      // Get the restroom document.
      DocumentSnapshot restroomDoc =
      await _firestore.collection("restrooms").doc(restroomDocId).get();

      if (restroomDoc.exists) {
        Map<String, dynamic> data =
            restroomDoc.data() as Map<String, dynamic>? ?? {};

        // Check if averageRating and reviewCount already exist.
        if (data.containsKey('averageRating') &&
            data.containsKey('reviewCount')) {
          double oldAvgRating = (data['averageRating'] as num).toDouble();
          int oldCount = data['reviewCount'] as int;

          double newAvgRating = ((oldAvgRating * oldCount) + _rating!) /
              (oldCount + 1);

          await _firestore.collection('restrooms').doc(restroomDocId).update({
            'reviewCount': FieldValue.increment(1),
            'averageRating': newAvgRating,
          });
        } else {
          // The document exists but does not have averageRating or reviewCount.
          await _firestore.collection('restrooms').doc(restroomDocId).update({
            'reviewCount': 1,
            'averageRating': _rating,
          });
        }
      } else {
        // The restroom document doesn't exist at all; create it.
        await _firestore.collection('restrooms').doc(restroomDocId).set({
          'reviewCount': 1,
          'averageRating': _rating,
        });
      }
    } catch (e) {
      print("Error submitting review: $e");
    }
  }
}
