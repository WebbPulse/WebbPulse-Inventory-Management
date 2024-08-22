import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreReadService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getOrg(String orgId) {
    try {
      DocumentReference documentRef =
          _db.collection('organizations').doc(orgId);
      return documentRef.snapshots();
    } catch (e) {
      return Stream.error('Failed to get organization');
    }
  }

  Stream<List<String>> getUserOrgsIds(String? uid) {
    if (uid == null) {
      return Stream.value([]);
    }

    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return List<String>.from(snapshot.data()?['userOrgIds'] ?? []);
    }).handleError((error) {
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
      return false;
    }
  }

  Stream<DocumentSnapshot> getOrgDevice(String? deviceId, String? orgId) {
    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .doc(deviceId);
      return documentRef.snapshots();
    } catch (e) {
      return Stream.error('Failed to get organization');
    }
  }

  Future<List<DocumentSnapshot>> getOrgDevices(String orgId) async {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('devices');
      QuerySnapshot querySnapshot = await collectionRef.get();
      return querySnapshot.docs;
    } catch (e) {
      return <DocumentSnapshot>[]; // Return an empty list in case of error
    }
  }

  Stream<List<DocumentSnapshot>> getOrgMemberDevices(
      String orgId, String orgMemberId) {
    CollectionReference collectionRef =
        _db.collection('organizations').doc(orgId).collection('devices');

    return collectionRef
        .where('deviceCheckedOutBy', isEqualTo: orgMemberId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs)
        .handleError((error) {
      return <DocumentSnapshot>[]; // Return an empty list in case of error
    });
  }

  Stream<List<DocumentSnapshot>> getOrgMembers(String orgId) {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('members');
      return collectionRef.snapshots().map((querySnapshot) {
        return querySnapshot.docs;
      });
    } catch (e) {
      return Stream.value(
          <DocumentSnapshot>[]); // Return an empty list in case of error
    }
  }

  Stream<DocumentSnapshot?> getOrgMember(String orgId, String orgMemberId) {
    if (orgMemberId.isEmpty) {
      return Stream.value(null);
    }

    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(orgMemberId);
      return documentRef.snapshots();
    } catch (e) {
      return Stream.error('Failed to get org member');
    }
  }

  Stream<DocumentSnapshot> getUser(String? uid) {
    try {
      DocumentReference documentRef = _db.collection('users').doc(uid);
      return documentRef.snapshots();
    } catch (e) {
      return Stream.error('Failed to get user');
    }
  }
}
