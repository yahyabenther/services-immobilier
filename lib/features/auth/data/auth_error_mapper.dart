import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/auth_failure.dart';

AuthFailure mapFirebaseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'invalid-verification-code':
      return const AuthFailure(AuthFailureType.invalidCredentials);
    case 'user-not-found':
      return const AuthFailure(AuthFailureType.userNotFound);
    case 'email-already-in-use':
      return const AuthFailure(AuthFailureType.emailAlreadyUsed);
    case 'weak-password':
      return const AuthFailure(AuthFailureType.weakPassword);
    case 'invalid-email':
      return const AuthFailure(AuthFailureType.invalidEmail);
    case 'too-many-requests':
      return const AuthFailure(AuthFailureType.tooManyRequests);
    case 'network-request-failed':
      return const AuthFailure(AuthFailureType.networkError);
    case 'user-disabled':
      return const AuthFailure(AuthFailureType.accountSuspended);
    case 'expired-action-code':
    case 'invalid-action-code':
      return const AuthFailure(AuthFailureType.invalidResetCode);
    case 'account-exists-with-different-credential':
    case 'credential-already-in-use':
      return const AuthFailure(AuthFailureType.googleSignInFailed);
    default:
      return const AuthFailure(AuthFailureType.unknown);
  }
}

AuthFailure mapFirebaseException(FirebaseException e) {
  if (e.code == 'unavailable' || e.code == 'network-request-failed' || e.code == 'deadline-exceeded') {
    return const AuthFailure(AuthFailureType.networkError);
  }
  return const AuthFailure(AuthFailureType.unknown);
}
