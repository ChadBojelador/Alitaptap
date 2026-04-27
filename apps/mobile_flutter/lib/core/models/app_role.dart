enum AppRole {
  student,
  admin,
}

extension AppRoleX on AppRole {
  static AppRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return AppRole.admin;
      case 'community': // legacy — treat as student
      case 'student':
      default:
        return AppRole.student;
    }
  }

  String get value {
    switch (this) {
      case AppRole.student:
        return 'student';
      case AppRole.admin:
        return 'admin';
    }
  }
}
