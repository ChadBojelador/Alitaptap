import 'package:flutter/material.dart';

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
    await _authService.signInAnonymously();
    final role = await _authService.getCurrentUserRole();
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
