import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';

// NOTE: cloud_firestore import removed — package commented out in pubspec.yaml
// to unblock Android build. Re-add when Android Gradle issue is resolved.
// import 'package:cloud_firestore/cloud_firestore.dart';

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
  AuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  // FirebaseFirestore removed — see class doc above.

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  /// BYPASSED — Firestore write disabled. See class-level doc.
  Future<void> setRole(String role) async {
    // TODO: re-enable once cloud_firestore is restored in pubspec.yaml.
    // await _firestore.collection('users').doc(_auth.currentUser?.uid).set(
    //   {'role': role, 'created_at': DateTime.now().toIso8601String()},
    //   SetOptions(merge: true),
    // );
  }

  /// BYPASSED — returns default student role. See class-level doc.
  Future<AppRole> getCurrentUserRole() async {
    // TODO: re-enable once cloud_firestore is restored in pubspec.yaml.
    // final user = _auth.currentUser;
    // if (user == null) return AppRole.student;
    // final doc = await _firestore.collection('users').doc(user.uid).get();
    // return AppRoleX.fromString(doc.data()?['role'] as String?);
    return AppRole.student;
  }
}
