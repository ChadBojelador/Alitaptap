import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/app_role.dart';

abstract class AuthRepository {
  Future<UserCredential> signInAnonymously();

  Future<void> setRole(String role);

  Future<AppRole> getCurrentUserRole();
}
