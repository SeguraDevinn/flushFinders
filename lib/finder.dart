import 'ParseMapData.dart';
import 'review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


class FinderPage extends StatefulWidget {
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage>
    with AutomaticKeepAliveClientMixin {
  final RestroomService _restroomService = RestroomService();
  late GoogleMapController mapController;
  late bool _serviceEnabled;
  late LatLng _mapCenter;
  late LatLng _currentPosition;
  bool _mapIsLoading = true;
  Set<Marker> _markers = {};
  bool _dataLoaded = false;
  bool _isLoadingRestrooms = false;


   Future<void> _getUserLocation() async {
    // update/create variables to see if location is enabled/has permission
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission;
    // check if the service is not enabled
    if (!_serviceEnabled) {
      print("Location services not enabled");
    }

    // Check if location permission is enabled
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location service denied!");
      }
    }

    //set user position
    Position userPos = await Geolocator.getCurrentPosition();
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      _currentPosition = LatLng(userPos.latitude, userPos.longitude);
      _mapCenter = _currentPosition;
    });
    await _initializeMapData();

  }


  Future<void> _initializeMapData() async {
    await _loadRestroomsToMap();
    if (!mounted) return;
    setState(() {
      _mapIsLoading = false;
    });
    await RestroomService.loadRestroomsFromAPI(_currentPosition);
    await _loadRestroomsToMap();
    _dataLoaded = true;
  }

  void _onMapCreated(GoogleMapController controller) {
     mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    if (!mounted) return;
     setState(() {
       _mapCenter = position.target;
     });
  }

  Future<void> _onSearchHerePressed() async {
     setState(() {
       _isLoadingRestrooms = true;
     });


     print("Searching for restrooms here: ${_mapCenter}");
     await RestroomService.loadRestroomsFromAPI(_mapCenter);
     await _loadRestroomsToMap();

     setState(() {
       _isLoadingRestrooms = false;
     });

  }

  @override
  void initState() {
    super.initState();
    // check to see if the data is already loaded, if it is then skip, else init
    _getUserLocation();
  }

  Future<void> _loadRestroomsToMap() async {
    final restrooms = await RestroomService.getRestrooms();
    Set<String> existingRestroomIds =
        _markers.map((marker) => marker.markerId.value).toSet();

    final newMarkers = restrooms
        .where((restroom) =>
            !existingRestroomIds.contains(restroom['id'].toString()))
        .map((restroom) {
      return Marker(
        markerId: MarkerId(restroom['id'].toString()),
        position: LatLng(restroom['latitude'], restroom['longitude']),
        infoWindow: InfoWindow(
          title: restroom['name'],
          snippet: restroom['comment'],
        ),
        onTap: () => _showRestroomDetails(context, restroom),
      );
    }).toSet();
    if (mounted) {
      setState(() {
        _markers.addAll(newMarkers);
      });
    }
  }

  void _showRestroomDetails(BuildContext context, Map<String, dynamic> restroom) {
    // Helper function to build the star rating widget.
    Widget _buildRatingStars(Map<String, dynamic> restroom) {
      if (restroom.containsKey('averageRating') && restroom['averageRating'] != null) {
        double avgRating = 0.0;
        try {
          avgRating = (restroom['averageRating'] as num).toDouble();
        } catch (e) {
          avgRating = 0.0;
        }
        List<Widget> stars = [];
        for (int i = 1; i <= 5; i++) {
          if (avgRating >= i) {
            stars.add(const Icon(Icons.star, color: Colors.amber));
          } else if (avgRating > i - 1 && avgRating < i) {
            stars.add(const Icon(Icons.star_half, color: Colors.amber));
          } else {
            stars.add(const Icon(Icons.star_border, color: Colors.grey));
          }
        }
        return Row(
          children: [
            ...stars,
            const SizedBox(width: 8),
            Text(avgRating.toStringAsFixed(1)),
          ],
        );
      } else {
        // No rating exists: show 5 gray stars and a message.
        return Row(
          children: const [
            Icon(Icons.star_border, color: Colors.grey),
            Icon(Icons.star_border, color: Colors.grey),
            Icon(Icons.star_border, color: Colors.grey),
            Icon(Icons.star_border, color: Colors.grey),
            Icon(Icons.star_border, color: Colors.grey),
            SizedBox(width: 8),
            Text("(no ratings yet)", style: TextStyle(color: Colors.grey)),
          ],
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the content to scroll
      backgroundColor: Colors.transparent, // Make the background transparent
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3, // Start with 30% height of the screen
          minChildSize: 0.3, // Minimum height when collapsed
          maxChildSize: 0.9, // Maximum height when fully expanded (90% of screen height)
          builder: (BuildContext context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, // White background for the content
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Column(
                children: [
                  // Handle line to indicate swipe-up functionality
                  Container(
                    width: 75, // Width of the handle line
                    height: 3, // Height of the handle line
                    color: Colors.grey[300], // Light grey color for the handle
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Main content of the modal
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController, // Allows smooth scrolling
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row for name of location and accessibility
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Make the name scrollable if it's too long
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal, // Horizontal scroll
                                    child: Text(
                                      restroom['name'] ?? "Restroom Info",
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                // Amenities row (icons)
                                Row(
                                  children: [
                                    if (restroom['accessible'] == true)
                                      const Icon(Icons.accessibility, color: Colors.green),
                                    if (restroom['unisex'] == true)
                                      Row(
                                        children: const [
                                          Icon(Icons.male, color: Colors.green),
                                          Text('|', style: TextStyle(color: Colors.green)),
                                          Icon(Icons.female, color: Colors.green),
                                        ],
                                      ),
                                    if (restroom['changing_table'] == true)
                                      const Icon(Icons.child_care, color: Colors.green),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Star rating row based on the average rating
                            _buildRatingStars(restroom),
                            const SizedBox(height: 16),
                            // Directions and Review buttons on the same row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // Scroll horizontally
                              child: Row(
                                children: [
                                  // Directions button
                                  ElevatedButton(
                                    onPressed: () => _launchMapsDirections(
                                        restroom['latitude'], restroom['longitude']),
                                    child: const Text("Get Directions"),
                                  ),
                                  const SizedBox(width: 8), // Space between buttons
                                  // Review button
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewPage(
                                            restroomId: restroom['id'],
                                            restroomName: restroom['name'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text("Review"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // TabBar for Overview and Reviews
                            DefaultTabController(
                              length: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const TabBar(
                                    tabs: [
                                      Tab(text: "Overview"),
                                      Tab(text: "Reviews"),
                                    ],
                                  ),
                                  Container(
                                    height: 300, // Fixed height for the TabBarView
                                    child: TabBarView(
                                      children: [
                                        // Overview Tab Content
                                        SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "In store directions: ${restroom['directions']?.isNotEmpty == true ? restroom['directions'] : "No directions available"}",
                                                  style: const TextStyle(fontSize: 16),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  "Comment: ${restroom['comment']?.isNotEmpty == true ? restroom['comment'] : 'No comments available'}",
                                                  style: const TextStyle(fontSize: 16),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Reviews Tab Content
                                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection('restrooms')
                                              .doc(restroom['id'].toString())
                                              .collection('reviews')
                                              .orderBy('timestamp', descending: true)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }
                                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                              return const Center(child: Text("No reviews available"));
                                            }
                                            return ListView.builder(
                                              itemCount: snapshot.data!.docs.length,
                                              itemBuilder: (context, index) {
                                                // Get the review document data
                                                var reviewDoc = snapshot.data!.docs[index];
                                                var reviewData = reviewDoc.data();
                                                // Extract information; adjust as needed
                                                double rating = (reviewData['rating'] is int)
                                                    ? (reviewData['rating'] as int).toDouble()
                                                    : (reviewData['rating'] as double);
                                                String comment = reviewData['comment'] ?? "";
                                                List<dynamic> pros = reviewData['pros'] ?? [];
                                                List<dynamic> cons = reviewData['cons'] ?? [];
                                                return Card(
                                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: ListTile(
                                                    leading: const Icon(Icons.star, color: Colors.amber),
                                                    title: Text("Rating: $rating"),
                                                    subtitle: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (comment.isNotEmpty) Text("Comment: $comment"),
                                                        if (pros.isNotEmpty) Text("Pros: ${pros.join(', ')}"),
                                                        if (cons.isNotEmpty) Text("Cons: ${cons.join(', ')}"),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Suggest an Edit Button at the bottom
                            ElevatedButton(
                              onPressed: () {
                                // TODO: ADD LOGIC FOR "Suggest an edit"
                              },
                              child: const Text("Suggest an edit"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchMapsDirections(double latitude, double longitude) async {
    if (Platform.isIOS) {
      final Uri appleMapsUri = Uri.parse('maps:0,0?q=$latitude,$longitude.');
      try {
        if (await canLaunchUrl(appleMapsUri)) {
          await launchUrl(appleMapsUri);
        } else {
          throw 'Could not open apple maps';
        }
      } catch (e) {
        print("Error launching apple maps: $e");
      }
    } else {
      //TODO: add logic for android
      print('Platform is not IOS');
    }
  }


  @override
  void dispose() {
    //mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          // 🔹 Google Map as the Background
          Positioned.fill(
            child: _mapIsLoading
                ? const Center(child: CircularProgressIndicator()) // Show circular loading when initializing map
                : GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              mapType: MapType.normal,
            ),
          ),

          // 🔹 Search Bar Positioned 15% Down from the Top
          Positioned(
            top: MediaQuery.of(context).size.height * 0.06, // 6% down from the screen height
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search here...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  // Placeholder: Implement search functionality here
                },
              ),
            ),
          ),

          // 🔹 Loading Bar (if restrooms are being loaded)
          if (_isLoadingRestrooms)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.12, // Below search bar
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onSearchHerePressed,
        label: const Text('Search Here'),
        icon: const Icon(Icons.search),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}