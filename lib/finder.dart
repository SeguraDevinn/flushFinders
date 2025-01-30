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

class _FinderPageState extends State<FinderPage> {
  final RestroomService _restroomService = RestroomService();
  late GoogleMapController mapController;
  late LatLng _currentPosition;
  bool _mapIsLoading = true;
  late bool _serviceEnabled;
  late loc.PermissionStatus _permissionGranted;
  late loc.LocationData _locationData;
  late loc.Location location;
  Set<Marker> _markers = {};




  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToUserLocation();
  }


  @override
  void initState() {
    super.initState();
    location = loc.Location();

    _tempLocationSet();
    RestroomService.loadRestroomsFromAPI();
    _loadRestroomsToMap();
      //_requestLocation();
  }

  void _tempLocationSet() {
    _mapIsLoading = false;
    _currentPosition = LatLng(33.93174, -117.425221);
  }

  Future<void> _loadRestroomsToMap() async {
    final restrooms = await RestroomService.getRestrooms();
    setState(() {
      _markers = restrooms.map((restroom) {
        return Marker(
          markerId: MarkerId(restroom['id'].toString()),
          position: LatLng(restroom['latitude'], restroom['longitude']),
          infoWindow: InfoWindow(title: restroom['name'], snippet: restroom['comment']),

        );
      }).toSet();
    });
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
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapIsLoading = false;
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition),
      );
    } catch (e) {
      print("Error fetching Location $e");
    }
  }

  void _moveToUserLocation() {
    mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finder"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _mapIsLoading ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPosition,
          zoom: 16.0,
          ),
        markers: _markers,
        myLocationEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
