import 'ParseMapData.dart';
import 'review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class FinderPage extends StatefulWidget {
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage>
    with AutomaticKeepAliveClientMixin {
  final RestroomService _restroomService = RestroomService();
  late GoogleMapController mapController;
  late LatLng _currentPosition;
  bool _mapIsLoading = true;
  late bool _serviceEnabled;
  late loc.PermissionStatus _permissionGranted;
  late loc.LocationData _locationData;
  late loc.Location location;
  Set<Marker> _markers = {};
  bool _dataLoaded = false;

/*
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToUserLocation();
  }

 */

  @override
  void initState() {
    super.initState();
    location = loc.Location();
    // check to see if the data is already loaded, if it is then skip, else init
    if (!_dataLoaded) {
      _initializeMapData();
    }
  }

  Future<void> _initializeMapData() async {
    _tempLocationSet();
    //await _requestLocation();
    await _loadRestroomsToMap();
    //TODO: make sure to uncomment this for API to work. Also, pull from firebase then check api, then pull from database again.
    //await RestroomService.loadRestroomsFromAPI(_currentPosition);
    _dataLoaded = true;
  }

  void _tempLocationSet() {
    //set the state of the maplaoding and set current pos
    _mapIsLoading = false;
    _currentPosition = LatLng(33.93174, -117.425221);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // Allows the content to scroll
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
                    width: 75,  // Width of the handle line
                    height: 3,  // Height of the handle line
                    color: Colors.grey[300],  // Light grey color for the handle
                    margin: EdgeInsets.symmetric(vertical: 8),
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
                                    scrollDirection: Axis.horizontal,  // Horizontal scroll
                                    child: Text(
                                      restroom['name'] ?? "Restroom Info",
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                // Amenities row (icons)
                                Row(
                                  children: [
                                    if (restroom['accessible'] == true)
                                      Icon(Icons.accessibility, color: Colors.green),
                                    if (restroom['unisex'] == true)
                                      Row(
                                        children: [
                                          Icon(Icons.male, color: Colors.green),
                                          Text('|', style: TextStyle(color: Colors.green)),
                                          Icon(Icons.female, color: Colors.green),
                                        ],
                                      ),
                                    if (restroom['changing_table'] == true)
                                      Icon(Icons.child_care, color: Colors.green),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                // Placeholder for star rating
                                Icon(Icons.star, color: Colors.amber),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Directions and Review buttons on the same height with small space between
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // Scroll horizontally
                              child: Row(
                                children: [
                                  // Directions button start
                                  ElevatedButton(
                                    onPressed: () => _launchMapsDirections(
                                        restroom['latitude'], restroom['longitude']),
                                    child: Text("Get Directions"),
                                  ),
                                  SizedBox(width: 8), // Horizontal space between the buttons
                                  // Review button start
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: ADD LOGIC FOR REVIEW BUTTON
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ReviewPage(
                                              restroomId : restroom['id'],
                                              restroomName: restroom['name'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text("Review"),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // TabBar for Overview and Reviews
                            DefaultTabController(
                              length: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TabBar(
                                    tabs: [
                                      Tab(text: "Overview"),
                                      Tab(text: "Reviews"),
                                    ],
                                  ),
                                  Container(
                                    height: 300, // Set a fixed height for the TabBarView
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
                                                  style: TextStyle(fontSize: 16),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  "Comment: ${restroom['comment']?.isNotEmpty == true ? restroom['comment'] : 'No comments available'}",
                                                  style: TextStyle(fontSize: 16),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text("No reviews available"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Suggest an Edit Button that appears at the bottom
                            ElevatedButton(
                              onPressed: () {
                                // TODO: ADD LOGIC FOR "Suggest an edit"
                              },
                              child: Text("Suggest an edit"),
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

  Future<void> _requestLocation() async {
    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        _getUserLocation();
        return;
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapIsLoading = false;

      mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    } catch (e) {
      print("Error fetching Location $e");
    }
  }

  void _moveToUserLocation() {
    mapController.animateCamera(
      CameraUpdate.newLatLng(_currentPosition),
    );
  }

  @override
  void dispose() {
    //mapController.dispose();
    //location.onLocationChanged.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //AutomaticKeepAliveClientMixin requires this to keep its state
    super.build(context);
    return Scaffold(
      body: _mapIsLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              mapType: MapType.normal,
            ),
    );
  }

  //foreces the map to keep its state even when leaving the screen.
  @override
  bool get wantKeepAlive => true;
}
