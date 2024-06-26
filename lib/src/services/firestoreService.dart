import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<String>> orgsUidsStream(String? uid) {
    if (uid == null) {
      return Stream.value([]);
    }
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return List<String>.from(snapshot.data()?['organizationUids'] ?? []);
    }).handleError((error) {
      print('Error getting organizations: $error');
      return Stream.value([]);
    });
  }

  Stream<bool> checkUserExistsInFirestoreStream(String? uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return snapshot.exists;
    }).handleError((e) {
      print('Error checking user exists: $e');
      return false;
    });
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
        'createdAt': FieldValue.serverTimestamp(),
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

  Stream<String> getOrgNameStream(String orgUid) {
    return _db
        .collection('organizations')
        .doc(orgUid)
        .snapshots()
        .map((snapshot) {
      return (snapshot.data()?['name'] ?? '') as String;
    }).handleError((e) {
      print('Error checking organization name: $e');
      return '';
    });
  }

  Stream<List<String>> getDevicesUidsStream(String? orgUid) {
    if (orgUid == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgUid)
        .collection('devices')
        .snapshots()
        .map((querySnapshot) {
      final documentUIDs = querySnapshot.docs.map((doc) => doc.id).toList();
      return documentUIDs;
    }).handleError((e) {
      print('Error retrieving document UIDs: $e');
      return <String>[]; // Return an empty list in case of error
    });
  }
}
