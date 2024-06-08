import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrganization(String organizationName, String uid) async {
    await _db.collection('organizations').add({
      'name': organizationName,
      'members': [uid],
    });
  }
}
