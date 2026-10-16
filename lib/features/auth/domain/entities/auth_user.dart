enum UserRole {
  user,
  owner,
  agent,
  admin;

  /// Unknown / missing role falls back to the least-privileged one.
  static UserRole parse(String? v) =>
      UserRole.values.firstWhere((r) => r.name == v, orElse: () => UserRole.user);
}

enum AccountStatus {
  active,
  suspended,
  banned,
  pending,
  deleted;

  /// Missing status -> active (profile not created yet).
  /// Unknown value -> suspended (fail closed).
  static AccountStatus parse(String? v) {
    if (v == null) return AccountStatus.active;
    return AccountStatus.values.firstWhere(
      (s) => s.name == v,
      orElse: () => AccountStatus.suspended,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.role = UserRole.user,
    this.status = AccountStatus.active,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final bool emailVerified;

  bool get isAdmin => role == UserRole.admin;

  /// suspended / banned / deleted accounts must not reach the application.
  bool get isBlocked =>
      status == AccountStatus.suspended ||
      status == AccountStatus.banned ||
      status == AccountStatus.deleted;
}
