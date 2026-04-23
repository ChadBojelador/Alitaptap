import 'package:shared_preferences/shared_preferences.dart';

/// Replaces FirebaseAuth — stores uid, email, role locally.
class SessionService {
  static const _keyUid = 'session_uid';
  static const _keyEmail = 'session_email';
  static const _keyRole = 'session_role';

  static String _uid = '';
  static String _email = '';
  static String _role = '';

  static String get uid => _uid;
  static String get email => _email;
  static String get role => _role;
  static bool get isLoggedIn => _uid.isNotEmpty;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString(_keyUid) ?? '';
    _email = prefs.getString(_keyEmail) ?? '';
    _role = prefs.getString(_keyRole) ?? '';
  }

  static Future<void> save({
    required String uid,
    required String email,
    required String role,
  }) async {
    _uid = uid;
    _email = email;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
  }

  static Future<void> clear() async {
    _uid = '';
    _email = '';
    _role = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
  }
}
