import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  final int restroomId; // ID of the restroom being reviewed
  final String restroomName; // Name of the restroom

  ReviewPage({required this.restroomId, required this.restroomName});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double? _rating;
  List<String> _selectedPros = [];
  List<String> _selectedCons = [];
  String _comment = "";

  final List<String> prosList = ["Toilet Paper", "Wax Paper", "Clean", "Soap", "Hand Dryer"];
  final List<String> consList = ["No Toilet Paper", "Dirty", "Crowded", "No Soap", "No Hand Dryer"];

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
                      index < (_rating ?? 0) ? Icons.star : Icons.star_border,
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
                onPressed: () {
                  if (_rating != null) {
                    //submitReview();
                  } else {
                    // Show a message to the user to select a rating
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please provide a rating')),
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


}
