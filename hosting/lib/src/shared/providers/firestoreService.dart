import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getOrgStream(String orgId) {
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
      return List<String>.from(snapshot.data()?['userOrgIds'] ?? []);
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
      return querySnapshot.docs.first.data()['isDeviceCheckedOut'];
    } catch (e) {
      print('Error checking device checkout status: $e');
      return false;
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
      return data['isDeviceCheckedOut'] as bool? ?? false;
    }).handleError((e) {
      print('Error checking device data: $e');
      return false;
    });
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

  Future<List<DocumentSnapshot>> getOrgMemberDevices(
      String orgId, String orgMemberId) async {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('devices');
      QuerySnapshot querySnapshot = await collectionRef
          .where('deviceCheckedOutBy', isEqualTo: orgMemberId)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting organization member devices: $e');
      return <DocumentSnapshot>[]; // Return an empty list in case of error
    }
  }

  Stream<List<DocumentSnapshot>> getOrgMembers(String orgId) {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('members');
      return collectionRef.snapshots().map((querySnapshot) {
        return querySnapshot.docs;
      });
    } catch (e) {
      print('Error getting organization members: $e');
      return Stream.value(
          <DocumentSnapshot>[]); // Return an empty list in case of error
    }
  }

  Stream<DocumentSnapshot> getOrgMemberStream(
      String orgId, String orgMemberId) {
    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(orgMemberId);
      return documentRef.snapshots();
    } catch (e) {
      print('Error getting org member: $e');
      return Stream.error('Failed to get org member');
    }
  }

  Stream<DocumentSnapshot> getUserStream(String? uid) {
    try {
      DocumentReference documentRef = _db.collection('users').doc(uid);
      return documentRef.snapshots();
    } catch (e) {
      print('Error getting user: $e');
      return Stream.error('Failed to get user');
    }
  }
}
