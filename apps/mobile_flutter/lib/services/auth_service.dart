import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';

/// Firebase Auth + Firestore service for user identity and role management.
///
/// ## BYPASS NOTE — setRole() and getCurrentUserRole()
/// Both [setRole] and [getCurrentUserRole] interact with Firestore.
/// They are currently NOT called from the app because Firestore security
/// rules have not been configured yet, causing "permission-denied" errors.
///
/// What was bypassed:
///   - [setRole] — was called in SignInPage after the user picks a role.
///     Removed to avoid the permission-denied crash on the users/{uid} write.
///   - [getCurrentUserRole] — was called in AlitaptapApp._bootstrapRole on
///     launch to skip the sign-in screen for returning users.
///     Removed along with the entire _bootstrapRole method.
///
/// Current behaviour: role is passed in-memory from SignInPage directly to
/// the app router. No Firestore reads or writes happen for role management.
///
/// To restore full persistence:
///   1. Add Firestore rules (see docs/00-governance/firebase-setup.md):
///      match /users/{userId} {
///        allow read, write: if request.auth != null
///                           && request.auth.uid == userId;
///      }
///   2. Uncomment `await _authService.setRole(...)` in SignInPage._proceed.
///   3. Re-add _bootstrapRole in AlitaptapApp to read role on launch.
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
