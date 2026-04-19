import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  /// Persists the chosen role to Firestore so subsequent launches skip sign-in.
  Future<void> setRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set(
      {'role': role, 'created_at': DateTime.now().toIso8601String()},
      SetOptions(merge: true),
    );
  }

  Future<AppRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return AppRole.student;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return AppRoleX.fromString(doc.data()?['role'] as String?);
  }
}
