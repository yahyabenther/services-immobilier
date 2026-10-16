import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/property_discovery/domain/publish_permission.dart';

AuthUser u(UserRole r, {AccountStatus s = AccountStatus.active, bool verified = true}) =>
    AuthUser(id: '1', email: 'a@b.co', role: r, status: s, emailVerified: verified);

void main() {
  test('owner, agent, admin may see the CTA', () {
    for (final r in [UserRole.owner, UserRole.agent, UserRole.admin]) {
      expect(canPublishProperty(u(r)), isTrue, reason: r.name);
    }
  });
  test('plain users, guests, blocked and unverified may not', () {
    expect(canPublishProperty(u(UserRole.user)), isFalse);
    expect(canPublishProperty(null), isFalse);
    expect(canPublishProperty(u(UserRole.owner, s: AccountStatus.suspended)), isFalse);
    expect(canPublishProperty(u(UserRole.owner, verified: false)), isFalse);
  });
}
