/// Pure form validators (unit-tested). Each returns an error message or null.
class Validators {
  Validators._();

  static const minPasswordLength = 8;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  // Tunisian numbers: optional +216 / 00216 / 216 prefix + 8 digits starting 2,3,4,5,7 or 9.
  static final _tnPhone = RegExp(r'^(?:\+216|00216|216)?([2-579]\d{7})$');

  static String _cleanPhone(String v) => v.replaceAll(RegExp(r'[\s\-().]'), '');

  static String? fullName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Full name is required';
    if (value.length < 3) return 'Full name is too short';
    return null;
  }

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!_email.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Phone number is required';
    if (!_tnPhone.hasMatch(_cleanPhone(value))) return 'Enter a valid phone number';
    return null;
  }

  /// Returns the phone as `+216XXXXXXXX` (or the trimmed input if it is invalid).
  static String normalizePhone(String v) {
    final m = _tnPhone.firstMatch(_cleanPhone(v.trim()));
    return m == null ? v.trim() : '+216${m.group(1)}';
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Password is required';
    final r = passwordRules(value);
    if (!r.minLength) return 'At least $minPasswordLength characters';
    if (!r.uppercase) return 'Add one uppercase letter';
    if (!r.number) return 'Add one number';
    return null;
  }

  /// Login only checks presence: the server decides whether credentials are valid.
  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Password is required' : null;

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static ({bool minLength, bool uppercase, bool number}) passwordRules(String v) => (
        minLength: v.length >= minPasswordLength,
        uppercase: RegExp(r'[A-Z]').hasMatch(v),
        number: RegExp(r'\d').hasMatch(v),
      );
}
