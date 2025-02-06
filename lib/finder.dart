import 'ParseMapData.dart';
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

  void _showRestroomDetails(
      BuildContext context, Map<String, dynamic> restroom) {
    //Todo: Change so that can still move map even when on a marker.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Row start for name of location and accessiblilty
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      restroom['name'] ?? "Restroom Info",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    //Ammenities start
                    Row(
                      children: [
                        if (restroom['accessible'] == true)
                          Icon(Icons.accessible, color: Colors.green),
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
                SizedBox(height: 16),
                Text(
                  "Comment: ${restroom['comment'] ?? 'No comment available'}",
                  style: TextStyle(fontSize: 16),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Directions: ${restroom['directions'] ?? "No directions avaliable"}",
                  style: TextStyle(fontSize: 16),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    /// TODO: Change this to a toilet paper and add
                    ///       reviews when integrated
                    Icon(Icons.star, color: Colors.amber),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: ADD LOGIC HERE
                        },
                        child: Text("Review"),
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 16),
                // Directions button
                ElevatedButton(
                  onPressed: () => _launchMapsDirections(
                      restroom['latitude'], restroom['longitude']),
                  child: Text("Get Directions"),
                ),
              ],
            ),
          ),
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
