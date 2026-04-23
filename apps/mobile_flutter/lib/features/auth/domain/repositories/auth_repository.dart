import '../../../../core/models/app_role.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password, required String role});
  Future<void> signOut();
  Future<void> setRole(String role);
  Future<AppRole> getCurrentUserRole();
}
