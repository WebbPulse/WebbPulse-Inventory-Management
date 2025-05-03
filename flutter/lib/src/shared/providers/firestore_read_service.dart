import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class that provides various Firestore read operations
class FirestoreReadService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance; // Firestore instance

  /// Stream that returns a DocumentSnapshot for an organization document
  Stream<DocumentSnapshot> getOrgDocument(String orgId) {
    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId); // Reference to the organization document
      return documentRef.snapshots(); // Return the document snapshot stream
    } catch (e) {
      return Stream.error(
          'Failed to get organization'); // Return an error stream in case of failure
    }
  }

  Stream<DocumentSnapshot> getOrgVerkadaIntegrationDocument(String orgId) {
    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('sensitiveConfigs')
          .doc('verkadaIntegrationSettings');
      return documentRef.snapshots();
    } catch (e) {
      return Stream.error(
          'Failed to get organization verkada integration info');
    }
  }

  /// Stream that returns a list of organization IDs that the user is a part of
  Stream<List<String>> getUserOrgsIds(String? uid) {
    if (uid == null) {
      return Stream.value([]); // Return an empty list if the UID is null
    }

    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return List<String>.from(snapshot.data()?['userOrgIds'] ??
          []); // Map the document data to a list of organization IDs
    }).handleError((error) {
      return Stream.value([]); // Return an empty list in case of error
    });
  }

  /// Check if a device exists in Firestore based on its serial number and organization ID
  Future<bool> doesDeviceExistInFirestore(
      String? deviceSerialNumber, String? orgId) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('deviceSerialNumber', isEqualTo: deviceSerialNumber)
          .get();
      return querySnapshot
          .docs.isNotEmpty; // Return true if the device exists, otherwise false
    } catch (e) {
      return false; // Return false in case of error
    }
  }

  /// Check if a device is checked out in Firestore based on its serial number and organization ID
  Future<bool> isDeviceCheckedOutInFirestore(
      String? serial, String? orgId) async {
    try {
      final querySnapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('deviceSerialNumber', isEqualTo: serial)
          .get();
      return querySnapshot.docs.first
          .data()['isDeviceCheckedOut']; // Return the check-out status
    } catch (e) {
      return false; // Return false in case of error
    }
  }

  /// Stream that checks if a device is checked out in Firestore based on its serial number and organization ID
  Stream<bool> isDeviceCheckedOutInFirestoreStream(
      String? serial, String? orgId) {
    try {
      return _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .where('deviceSerialNumber', isEqualTo: serial)
          .snapshots()
          .map((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.data()['isDeviceCheckedOut'];
        }
        return false; // Return false if no documents match
      });
    } catch (e) {
      return Stream.value(false); // Return false in case of error
    }
  }

  /// Stream that returns a DocumentSnapshot for a device document in an organization
  Stream<DocumentSnapshot> getOrgDeviceDocument(
      String? deviceId, String? orgId) {
    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('devices')
          .doc(deviceId);
      return documentRef.snapshots(); // Return the document snapshot stream
    } catch (e) {
      return Stream.error(
          'Failed to get organization'); // Return an error stream in case of failure
    }
  }

  /// Stream that returns a list of all device documents in an organization
  Stream<List<DocumentSnapshot>> getOrgDevicesDocuments(
      String orgId, String? orgMemberId) {
    CollectionReference collectionRef =
        _db.collection('organizations').doc(orgId).collection('devices');

    if (orgMemberId != null) {
      return collectionRef
          .where('deviceCheckedOutBy', isEqualTo: orgMemberId)
          .snapshots()
          .map((querySnapshot) =>
              querySnapshot.docs) // Map the query result to a list of documents
          .handleError((error) {
        return <DocumentSnapshot>[]; // Return an empty list in case of error
      });
    } else {
      return collectionRef.snapshots().map((querySnapshot) {
        return querySnapshot.docs; // Return a list of device documents
      }).handleError((error) {
        return <DocumentSnapshot>[]; // Return an empty list in case of error
      });
    }
  }

  /// Stream that returns a list of member documents in an organization
  Stream<List<DocumentSnapshot>> getOrgMembersDocuments(String orgId) {
    try {
      CollectionReference collectionRef =
          _db.collection('organizations').doc(orgId).collection('members');
      return collectionRef.snapshots().map((querySnapshot) {
        return querySnapshot.docs; // Return a list of member documents
      });
    } catch (e) {
      return Stream.value(
          <DocumentSnapshot>[]); // Return an empty list in case of error
    }
  }

  /// Stream that returns a single member document from an organization based on the member ID
  Stream<DocumentSnapshot?> getOrgMemberDocument(
      String orgId, String orgMemberId) {
    if (orgMemberId.isEmpty) {
      return Stream.value(null); // Return null if the member ID is empty
    }

    try {
      DocumentReference documentRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(orgMemberId);
      return documentRef
          .snapshots(); // Return the member document snapshot stream
    } catch (e) {
      return Stream.error(
          'Failed to get org member'); // Return an error stream in case of failure
    }
  }

  /// Stream that returns a global user document based on the user ID (UID)
  Stream<DocumentSnapshot> getGlobalUserDocument(String? uid) {
    try {
      DocumentReference documentRef = _db.collection('users').doc(uid);
      return documentRef
          .snapshots(); // Return the global user document snapshot stream
    } catch (e) {
      return Stream.error(
          'Failed to get user'); // Return an error stream in case of failure
    }
  }

  /// Stream that checks if a global user exists in Firestore based on the user ID (UID)
  Stream<bool> doesGlobalUserExistInFirestore(String uid) {
    try {
      return _db
          .collection('usersMetadata')
          .doc(uid)
          .snapshots()
          .map((docSnapshot) {
        return docSnapshot
            .exists; // Return true if the user exists, otherwise false
      });
    } catch (e) {
      // Return a stream that emits `false` in case of error
      return Stream.value(false);
    }
  }
}
