import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'api_service.dart';
import 'session_service.dart';
import '../core/models/app_role.dart';

class AuthService {
  final _api = ApiService();
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

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

  Future<String> signInWithFacebook({String defaultRole = 'student'}) async {
    final loginResult = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    if (loginResult.status != LoginStatus.success) {
      throw Exception('Facebook sign-in cancelled');
    }
    final userData = await FacebookAuth.instance.getUserData(fields: 'email,id,name');
    final email = userData['email'] as String? ?? '${userData['id']}@facebook.com';
    final result = await _api.socialLogin(
      email: email,
      provider: 'facebook',
      providerId: userData['id'] as String,
      displayName: userData['name'] as String? ?? '',
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
    await FacebookAuth.instance.logOut().catchError((_) {});
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
