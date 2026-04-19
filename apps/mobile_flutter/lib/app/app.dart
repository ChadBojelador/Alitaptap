import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/home/presentation/admin_home_page.dart';
import '../features/home/presentation/community_home_page.dart';
import '../features/home/presentation/student_home_page.dart';
import '../services/auth_service.dart';

class AlitaptapApp extends StatefulWidget {
  const AlitaptapApp({super.key});

  @override
  State<AlitaptapApp> createState() => _AlitaptapAppState();
}

class _AlitaptapAppState extends State<AlitaptapApp> {
  final _authService = AuthService();
  AppRole? _role;

  Future<void> _bootstrapRole() async {
    try {
      await _authService.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final hint = switch (e.code) {
        'operation-not-allowed' =>
          'Enable Anonymous sign-in in Firebase Authentication.',
        'api-key-not-valid' =>
          'Check Firebase web API key and app configuration.',
        'app-not-authorized' =>
          'Add localhost/127.0.0.1 to Firebase Auth authorized domains.',
        _ => 'Check Firebase Auth setup, API key restrictions, and network.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth setup issue: $hint')),
      );
    } catch (_) {
      // Continue with role lookup; unauthenticated lookup defaults to student.
    }

    final role = await _authService.getCurrentUserRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALITAPTAP',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: _role == null
          ? SignInPage(onContinue: _bootstrapRole)
          : switch (_role!) {
              AppRole.community => const CommunityHomePage(),
              AppRole.student => const StudentHomePage(),
              AppRole.admin => const AdminHomePage(),
            },
    );
  }
}
