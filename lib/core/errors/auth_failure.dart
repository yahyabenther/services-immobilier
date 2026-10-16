/// Application-level authentication errors (spec §38).
///
/// The UI never sees Firebase exceptions: the data layer maps them to this type.
enum AuthFailureType {
  invalidCredentials,
  emailAlreadyUsed,
  weakPassword,
  invalidEmail,
  userNotFound,
  tooManyRequests,
  networkError,
  verificationRequired,
  accountSuspended,
  accountBanned,
  googleSignInFailed,
  googleCancelled,
  invalidResetCode,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.type);

  final AuthFailureType type;

  /// User-friendly message. Never contains raw backend error text.
  String get message => switch (type) {
        AuthFailureType.invalidCredentials => 'The email or password is incorrect.',
        AuthFailureType.emailAlreadyUsed => 'An account already exists with this email.',
        AuthFailureType.weakPassword => 'This password is too weak. Choose a stronger one.',
        AuthFailureType.invalidEmail => 'Please enter a valid email address.',
        // Same text as invalidCredentials on purpose: do not reveal which emails exist.
        AuthFailureType.userNotFound => 'The email or password is incorrect.',
        AuthFailureType.tooManyRequests => 'Too many attempts. Please wait a moment and try again.',
        AuthFailureType.networkError =>
          'Unable to connect to the server.\nPlease check your internet connection and try again.',
        AuthFailureType.verificationRequired => 'Please verify your email address to continue.',
        AuthFailureType.accountSuspended => 'This account has been suspended.',
        AuthFailureType.accountBanned => 'This account is no longer allowed to access ImmoFind.',
        AuthFailureType.googleSignInFailed => 'Google sign-in failed. Please try again.',
        AuthFailureType.googleCancelled => 'Google sign-in was cancelled.',
        AuthFailureType.invalidResetCode =>
          'This reset link is invalid or has expired. Please request a new one.',
        AuthFailureType.unknown => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => 'AuthFailure($type)';
}
