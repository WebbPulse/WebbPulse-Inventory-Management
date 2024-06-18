import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  Stream<List<String>> userOrganizationsStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final organizations =
              List<String>.from(data['organizationUids'] ?? []);
          print('User organizations fetched: $organizations');
          return organizations;
        }
      }
      print('User document not found.');
      return [];
    });
  }

  Future<bool> checkUserExistsInFirestore(String? uid) async {
    if (uid == null) {
      throw ('uid is null');
    }
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking user exists: $e');
      return false;
    }
  }

  Future<void> createUserInFirestore(String? uid, String? email) async {
    if (uid == null) {
      throw ('uid is null');
    }
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
      String organizationCreationName, String? uid) async {
    if (uid == null) {
      throw ('uid is null');
    }
    try {
      // Add the organization and capture the document reference
      DocumentReference organizationRef =
          await _db.collection('organizations').add({
        'name': organizationCreationName,
        'members': [uid],
      });

      // Get the organization ID
      String organizationId = organizationRef.id;

      // Update the user's document with the new organization ID
      await updateUserOrganizationsInFirestore(uid, organizationId);
    } catch (e) {
      print('Error creating organization: $e');
    }
  }

  Future<void> updateUserOrganizationsInFirestore(
      String? uid, String? organizationId) async {
    if (uid == null) {
      throw ('uid is null');
    }
    if (organizationId == null) {
      throw ('organizationId is null');
    }
    try {
      // Update the user's document with the new organization ID using arrayUnion
      await _db.collection('users').doc(uid).update({
        'organizationUids': FieldValue.arrayUnion([organizationId]),
      });
    } catch (e) {
      print('Error updating user organizations in Firestore: $e');
    }
  }
}
