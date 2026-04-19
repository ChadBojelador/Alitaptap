enum AppRole {
  community,
  student,
  admin,
}

extension AppRoleX on AppRole {
  static AppRole fromString(String? value) {
    switch (value) {
      case 'community':
        return AppRole.community;
      case 'admin':
        return AppRole.admin;
      case 'student':
      default:
        return AppRole.student;
    }
  }

  String get value {
    switch (this) {
      case AppRole.community:
        return 'community';
      case AppRole.student:
        return 'student';
      case AppRole.admin:
        return 'admin';
    }
  }
}
