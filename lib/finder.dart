import 'ParseMapData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:dio/dio.dart';



class FinderPage extends StatefulWidget{
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> with AutomaticKeepAliveClientMixin {
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
    await RestroomService.loadRestroomsFromAPI(_currentPosition);
    await _loadRestroomsToMap();
    _dataLoaded = true;
  }

  void _tempLocationSet() {
    //set the state of the maplaoding and set current pos
    _mapIsLoading = false;
    _currentPosition = LatLng(33.93174, -117.425221);
  }

  Future<void> _loadRestroomsToMap() async {
    final restrooms = await RestroomService.getRestrooms();
    Set<String> existingRestroomIds = _markers.map((marker) => marker.markerId.value).toSet();
    if (mounted) {
      setState(() {
        _markers.addAll(
          restrooms.where((restroom) => !existingRestroomIds.contains(restroom['id'].toString()))
              .map((restroom) {
            return Marker(
              markerId: MarkerId(restroom['id'].toString()),
              position: LatLng(restroom['latitude'], restroom['longitude']),
              infoWindow: InfoWindow(
                  title: restroom['name'],
                  snippet: restroom['comment']),
            );
          }),
        );
      });
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

      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition),
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
      body: _mapIsLoading ? const Center(child: CircularProgressIndicator())
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
