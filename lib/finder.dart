import 'package:flutter/material.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


String style = "radar-default-v1";
String publishableKey = dotenv.env['RADAR_API_KEY'] ?? '';


class FinderPage extends StatefulWidget{
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  late MapController _mapController;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }


  Future<void> _getUserLocation() async {
    try {
      final location = await Radar.trackOnce();
      print(location);
      if (location != null) {
        final latitude = location['latitude'];
        final longitude = location['longitude'];

        setState(() {
          _userLocation = LatLng(latitude, longitude);
        });
      } else {
        print("Failed to get user location: location in null");
      }
    } catch (e) {
      print("failed to get location");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finder")),
      body: Stack(
        children: [ _userLocation == null ? Center(child: CircularProgressIndicator())
            : FlutterMap(
            mapController: _mapController,
            options: MapOptions (
              center: _userLocation,
              zoom: 14.0,
            ),
            children: [
              TileLayer (
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              )
            ],
          ),
        ],
      )
    );
  }
}
