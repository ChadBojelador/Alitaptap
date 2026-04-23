import '../services/api_service.dart';
import '../services/session_service.dart';
import '../core/models/app_role.dart';

class AuthService {
  final _api = ApiService();

  Future<void> signIn({required String email, required String password}) async {
    final result = await _api.signIn(email: email, password: password);
    await SessionService.save(
      uid: result['user_id'] as String,
      email: result['email'] as String,
      role: result['role'] as String,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _api.register(email: email, password: password, role: role);
    await SessionService.save(
      uid: result['user_id'] as String,
      email: result['email'] as String,
      role: result['role'] as String,
    );
  }

  Future<void> signOut() async {
    await SessionService.clear();
  }

  Future<void> setRole(String role) async {
    if (SessionService.uid.isEmpty) return;
    await _api.setUserRole(userId: SessionService.uid, role: role);
    await SessionService.save(
      uid: SessionService.uid,
      email: SessionService.email,
      role: role,
    );
  }

  Future<AppRole> getCurrentUserRole() async {
    return AppRoleX.fromString(SessionService.role);
  }
}
