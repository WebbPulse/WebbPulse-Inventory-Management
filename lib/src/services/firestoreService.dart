import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<String>> getOrganizations(String? uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      return List<String>.from(userDoc.data()?['organizationUids'] ?? []);
    } catch (e) {
      print('Error getting organizations: $e');
      return [];
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
