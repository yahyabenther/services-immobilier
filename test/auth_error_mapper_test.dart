import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/auth_failure.dart';
import 'package:team_app/features/auth/data/auth_error_mapper.dart';

void main() {
  AuthFailureType map(String code) =>
      mapFirebaseAuthException(FirebaseAuthException(code: code)).type;

  test('maps known codes', () {
    expect(map('invalid-credential'), AuthFailureType.invalidCredentials);
    expect(map('wrong-password'), AuthFailureType.invalidCredentials);
    expect(map('email-already-in-use'), AuthFailureType.emailAlreadyUsed);
    expect(map('weak-password'), AuthFailureType.weakPassword);
    expect(map('too-many-requests'), AuthFailureType.tooManyRequests);
    expect(map('network-request-failed'), AuthFailureType.networkError);
    expect(map('expired-action-code'), AuthFailureType.invalidResetCode);
  });

  test('unknown codes never leak raw text', () {
    final f = mapFirebaseAuthException(FirebaseAuthException(code: 'weird', message: 'RAW'));
    expect(f.type, AuthFailureType.unknown);
    expect(f.message.contains('RAW'), isFalse);
  });

  test('user-not-found shows the same text as wrong credentials', () {
    expect(const AuthFailure(AuthFailureType.userNotFound).message,
        const AuthFailure(AuthFailureType.invalidCredentials).message);
  });
}
