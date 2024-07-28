import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///should be moved server side
  Future<void> createDeviceInFirestore(String? serial, String? orgId) async {
    try {
      await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .add({
        'serial': serial,
        'createdAt': FieldValue.serverTimestamp(),
        'isCheckedOut': false,
      });
    } catch (e) {
      print('Error creating device: $e');
    }
  }

  Future<void> updateDeviceCheckoutStatusInFirestore(
      String? serial, String? orgId, bool isCheckedOut) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('serial', isEqualTo: serial)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _db
            .collection('organizations')
            .doc(orgId)
            .collection('devices')
            .doc(docId)
            .update({
          'isCheckedOut': isCheckedOut,
        });
      } else {
        print('Device not found');
      }
    } catch (e) {
      print('Error updating checkout status: $e');
    }
  }

  ///

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

  Future<List<String>> getDevicesUids(String? orgUid) async {
    if (orgUid == null) {
      return [];
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgUid)
          .collection('devices')
          .get();
      final documentUIDs = querySnapshot.docs.map((doc) => doc.id).toList();
      return documentUIDs;
    } catch (e) {
      print('Error retrieving device UIDs: $e');
      return <String>[]; // Return an empty list in case of error
    }
  }

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

  Stream<List<String>> getOrgMembersUidsStream(String? orgUid) {
    if (orgUid == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgUid)
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
      return (snapshot.data()?['username'] ?? '') as String;
    }).handleError((e) {
      print('Error checking username: $e');
      return '';
    });
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
}
