import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';

/// Firebase Auth + Firestore service for user identity and role management.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<void> setRole(String role) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(
      {'role': role, 'created_at': DateTime.now().toIso8601String()},
      SetOptions(merge: true),
    );
  }

  Future<AppRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return AppRole.student;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return AppRoleX.fromString(doc.data()?['role'] as String?);
  }
}
