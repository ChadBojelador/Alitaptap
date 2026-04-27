import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';
import 'session_service.dart';
import '../core/models/app_role.dart';

class AuthService {
  final _api = ApiService();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '350012830123-pg5tftq5iihe9q2qg3scqe7nv0be688f.apps.googleusercontent.com',
  );

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

  Future<String> signInWithGoogle({String defaultRole = 'student'}) async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');
    final result = await _api.socialLogin(
      email: account.email,
      provider: 'google',
      providerId: account.id,
      displayName: account.displayName ?? '',
      role: defaultRole,
    );
    await SessionService.save(
      uid: result['user_id'] as String,
      email: result['email'] as String,
      role: result['role'] as String,
    );
    return result['role'] as String;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) {});
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
