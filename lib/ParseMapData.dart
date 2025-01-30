import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
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


  static Future<void> loadRestroomsFromAPI() async {
    try {
      String jsonString = await rootBundle.loadString('/Users/devinnsegura/StudioProjects/Flush_Finders/assets/trialData.json');

      //Decode the json file
      List<dynamic> restrooms = json.decode(jsonString);

      //call save function to put in firebase
      await saveRestroomsToDatabase(restrooms);
      print("data successfully saved");
    } catch (e) {
      print('error loading or saving the restroms data: $e');
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

