import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
/*
*  This function is almost done, when I get back to this I need to
* make a fake call with the trail data.json and then from there I will decode
* it so that I can pass it to the saveRestroomsToDatabase. This will
* most likely be done in finder, when the map is loaded since that is when
* the user location is set and able to get the restrooms in the area.
* look in save JSON to firestore for a refresher.
* 
*
*
* */
class RestroomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String? userId = FirebaseAuth.instance.currentUser?.uid;
  static final String? email = FirebaseAuth.instance.currentUser?.email;
  static final String apiString = "https://zylalabs.com/api/2086/available+public+bathrooms+api/1869/get+public+bathrooms";
  static final String apiKey = dotenv.env['ZYLA_API_KEY'] ?? '';

  static Future<void> loadRestroomsFromAPI(LatLng location) async {
    try {
      final dio = Dio();


      final queryParams = {
        "lat": location.latitude.toString(),
        "lng": location.longitude.toString(),
        "page": "1",
        "per_page": "50",
        "offset": "0",
      };

      final fullRequestUrl = "$apiString?${Uri(queryParameters: queryParams).query}";
      print("Request URL: $fullRequestUrl");

      final response = await dio.get(
        apiString,
        queryParameters: queryParams,
        options: Options(
          headers: {"Authorization": "Bearer $apiKey"},
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          // Decode the json file if it's a list
          List<dynamic> restrooms = response.data;

          // Call save function to put data in firebase or another database
          await saveRestroomsToDatabase(restrooms);
          print("Data successfully saved.");
        } else {
          print("Unexpected response format: ${response.data}");
        }
      } else {
        print("Error fetching data: ${response.statusCode} - ${response.statusMessage}");
      }
    } on DioException catch (e) {
      // Print detailed error information from DioException
      print('DioException: ${e.response?.statusCode} ${e.response?.statusMessage}');
      print('Error Message: ${e.message}');
      print('StackTrace: ${e.stackTrace}');
    } catch (e, stackTrace) {
      // Catch any other type of error (e.g., network issues, unexpected errors)
      print('Error: $e');
      print('StackTrace: $stackTrace');
    }
  }

  static Future<void> saveRestroomsToDatabase(List<dynamic> restrooms) async {
    final CollectionReference restroomsCollection = _firestore.collection('restrooms');


    // Go through response and gather the data from each restrooms
    for (var restroom in restrooms) {
      String restroomId = restroom['id'].toString();

      try {
        bool exists = (await restroomsCollection.doc(restroomId).get()).exists;
        //check if the restroom is already in our database
        if (exists) {
          print('Restroom ${restroom['name']} already exists.');
          continue;
        }

        await restroomsCollection.doc(restroomId).set({
          'id': restroom['id'],
          'name': restroom['name'],
          'street': restroom['street'],
          'city': restroom['city'],
          'state': restroom['state'],
          'latitude': restroom['latitude'],
          'longitude': restroom['longitude'],
          'accessible': restroom['accessible'],
          'unisex': restroom['unisex'],
          'directions': restroom['directions'],
          'comment': restroom['comment'],
          'country': restroom['country'],
          'created_at': restroom['created_at'],
          'distance': restroom['distance'],
          'changing_table': restroom['changing_table'],
          'downvote': restroom['downvote'],
          'upvote': restroom['upvote'],
        });

        // print for confirmation of saved restroom
        print('Saved restroom: ${restroom['name']}');
      } catch (e) {
        print('Error processing restroom ${restroom['name']}: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getRestrooms() async {
    try {
      final querySnapshot = await _firestore.collection('restrooms').get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching restrooms: $e');
      return [];
    }
  }
}

