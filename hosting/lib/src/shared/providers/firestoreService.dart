import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getUserOrgStream(String orgId) {
    try {
      DocumentReference documentRef =
          _db.collection('organizations').doc(orgId);
      return documentRef.snapshots();
    } catch (e) {
      print('Error getting organization: $e');
      return Stream.error('Failed to get organization');
    }
  }

  Stream<List<String>> orgsIdsStream(String? uid) {
    if (uid == null) {
      return Stream.value([]);
    }

    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return List<String>.from(snapshot.data()?['orgIds'] ?? []);
    }).handleError((error) {
      print('Error getting organizations: $error');
      return Stream.value([]);
    });
  }

  Future<bool> doesDeviceExistInFirestore(
      String? deviceSerialNumber, String? orgId) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('deviceSerialNumber', isEqualTo: deviceSerialNumber)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking device exists: $e');
      return false;
    }
  }

  Future<bool> isDeviceCheckedOutInFirestore(
      String? serial, String? orgId) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('deviceSerialNumber', isEqualTo: serial)
          .get();
      return querySnapshot.docs.first.data()['isCheckedOut'];
    } catch (e) {
      print('Error checking device checkout status: $e');
      return false;
    }
  }

  Future<List<DocumentSnapshot>> getOrgDevices(String orgId) async {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('devices');
      QuerySnapshot querySnapshot = await collectionRef.get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting organization devices: $e');
      return <DocumentSnapshot>[]; // Return an empty list in case of error
    }
  }

  Stream<bool> deviceCheckoutStatusStream(String? deviceId, String? orgId) {
    if (deviceId == null || orgId == null) {
      return Stream.value(false);
    }
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return false;
      }
      return data['isCheckedOut'] as bool? ?? false;
    }).handleError((e) {
      print('Error checking device data: $e');
      return false;
    });
  }

  Future<List<DocumentSnapshot>> getOrgMembers(String orgId) async {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('members');
      QuerySnapshot querySnapshot = await collectionRef.get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting organization members: $e');
      return <DocumentSnapshot>[]; // Return an empty list in case of error
    }
  }
}
