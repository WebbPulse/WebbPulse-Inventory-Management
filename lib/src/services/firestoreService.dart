import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<String> organizationUids = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Object? _error;
  Object? get error => _error;

  Future<void> fetchOrganizations(String? uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (uid == null) {
      _isLoading = false;
      organizationUids = [];
      notifyListeners();
      return;
    }

    try {
      organizationUids = await getUserOrganizations(uid);
    } catch (e) {
      print('Error fetching organizations: $e');
      _error = e;
      organizationUids = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<String>> getUserOrganizations(String? uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return [];
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('organizationUids')) {
        return [];
      }

      final organizationUids = data['organizationUids'] as List<dynamic>?;
      return organizationUids?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('Error fetching user organizations: $e');
      throw e;
    }
  }

  Future<bool> checkUserExistsInFirestore(String? uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user exists: $e');
      return false;
    }
  }

  Future<void> createUserInFirestore(String? uid, String? email) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'organizationUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user: $e ');
    }
  }

  Future<void> createOrganizationInFirestore(
      String? organizationCreationName, String? uid) async {
    try {
      DocumentReference organizationRef =
          await _db.collection('organizations').add({
        'name': organizationCreationName,
        'members': [uid],
      });

      String organizationId = organizationRef.id;
      await updateUserOrganizationsInFirestore(uid, organizationId);
    } catch (e) {
      print('Error creating organization: $e');
    }
  }

  Future<void> updateUserOrganizationsInFirestore(
      String? uid, String? organizationId) async {
    try {
      await _db.collection('users').doc(uid).update({
        'organizationUids': FieldValue.arrayUnion([organizationId]),
      });
    } catch (e) {
      print('Error updating user organizations: $e');
    }
  }
}
