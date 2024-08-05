import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<String> getOrgNameStream(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .snapshots()
        .map((snapshot) {
      return (snapshot.data()?['name'] ?? '') as String;
    }).handleError((e) {
      print('Error checking organization name: $e');
      return '';
    });
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

  Future<bool> doesDeviceExistInFirestore(String? serial, String? orgId) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('serial', isEqualTo: serial)
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
          .where('serial', isEqualTo: serial)
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

  Stream<Map<String, dynamic>> getDeviceDataStream(
      String? deviceId, String? orgId) {
    if (deviceId == null || orgId == null) {
      return Stream.value({});
    }
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.data() ?? {};
    }).handleError((e) {
      print('Error checking device data: $e');
      return {};
    });
  }

  Stream<List<String>> getOrgMembersUidsStream(String? orgId) {
    if (orgId == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .snapshots()
        .map((querySnapshot) {
      final documentUIDs = querySnapshot.docs.map((doc) => doc.id).toList();
      return documentUIDs;
    }).handleError((e) {
      print('Error retrieving member UIDs: $e');
      return <String>[]; // Return an empty list in case of error
    });
  }

  Stream<String> getMemberDisplayNameStream(
      String? orgMembersUid, String? orgId) {
    if (orgMembersUid == null || orgId == null) {
      return Stream.value('');
    }
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(orgMembersUid)
        .snapshots()
        .map((snapshot) {
      return (snapshot.data()?['displayName'] ?? '') as String;
    }).handleError((e) {
      print('Error checking displayName: $e');
      return '';
    });
  }

  Stream<String> getCurrentDisplayName(String? uid) {
    if (uid == null) {
      return Stream.value('');
    }
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return (snapshot.data()?['displayName'] ?? '') as String;
    }).handleError((e) {
      print('Error getting current display name: $e');
      return '';
    });
  }
}
