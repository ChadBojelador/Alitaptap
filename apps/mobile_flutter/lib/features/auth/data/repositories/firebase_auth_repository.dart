import '../../../../core/models/app_role.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _authService = AuthService();

  @override
  Future<void> signIn({required String email, required String password}) =>
      _authService.signIn(email: email, password: password);

  @override
  Future<void> register({required String email, required String password, required String role}) =>
      _authService.register(email: email, password: password, role: role);

  @override
  Future<void> signOut() => _authService.signOut();

  @override
  Future<void> setRole(String role) => _authService.setRole(role);

  @override
  Future<AppRole> getCurrentUserRole() => _authService.getCurrentUserRole();
}
