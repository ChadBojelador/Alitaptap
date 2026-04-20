import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/app_role.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Future<UserCredential> signInAnonymously() {
    return _authService.signInAnonymously();
  }

  @override
  Future<void> setRole(String role) {
    return _authService.setRole(role);
  }

  @override
  Future<AppRole> getCurrentUserRole() {
    return _authService.getCurrentUserRole();
  }
}
