import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrganization(String orgName, User user) async {
    try {
      // Create organization in Firestore
      DocumentReference orgRef = await _firestore.collection('organizations').add({
        'name': orgName,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Link user to organization
      await _firestore.collection('users').doc(user.uid).collection('organizations').doc(orgRef.id).set({
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating organization: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrganizations(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> orgSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('organizations')
          .get();

      return orgSnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return doc.data();
      }).toList();
    } catch (e) {
      print('Error fetching user organizations: $e');
      return [];
    }
  }
}

