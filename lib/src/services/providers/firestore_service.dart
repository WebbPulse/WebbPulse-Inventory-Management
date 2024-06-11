import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService extends ChangeNotifier{

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;
  
  String? _uid;
  String? get uid => _uid;

  
  
  void handleAuthStateChange(String? authUid) {
    // Ensure uid is updated only if uid is not null
    if (authUid != null && authUid != _uid) {
      _uid = authUid;
      
      // Fetch user-related data from Firestore
      fetchUserOrganizations(_uid, authUid);

      // Notify listeners of the state change
      notifyListeners();
    }
  }

  List<String> _organizationUids = [];
  List<String> get organizationUids => _organizationUids;



  Future<void> createOrganizationInFirestore(String organizationName, String? uid) async {
    await _db.collection('organizations').add({
      'name': organizationName,
      'members': [uid],
    });
  }

  Future<void> updateUserOrganizationsInFirestore(String? uid) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'organizationUids': _organizationUids,
      });
    }
  }
  
  Future<void> fetchUserOrganizations(String? uid, String? authUid ) async {
    if (uid == null) {
      throw('uid is null');
    }
    
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      print('got to here');
      if (userDoc.exists) {
        _organizationUids = List<String>.from(userDoc.data()?['organizationUids'] ?? []);
      } 
      else {
        print('User document not found.');
        _organizationUids = [];
      }
      notifyListeners();
    } 
    on Exception catch (e) {
      print('Error fetching user organizations: $e');
      _organizationUids = [];
      notifyListeners();
    }
  }
}


