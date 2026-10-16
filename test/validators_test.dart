import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/utils/validators.dart';

// NOTE: replace `immofind` with the `name:` in your pubspec.yaml.
void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user@example.com  '), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('Tunisian phone is accepted and normalised', () {
      expect(Validators.phone('22 123 456'), isNull);
      expect(Validators.phone('+216 22 123 456'), isNull);
      expect(Validators.normalizePhone('22 123 456'), '+21622123456');
      expect(Validators.normalizePhone('0021622123456'), '+21622123456');
      expect(Validators.phone('12345678'), isNotNull); // cannot start with 1
      expect(Validators.phone(''), isNotNull);
    });

    test('password rules', () {
      expect(Validators.password('Abcdefg1'), isNull);
      expect(Validators.password('abcdefg1'), isNotNull); // no uppercase
      expect(Validators.password('Abcdefgh'), isNotNull); // no number
      expect(Validators.password('Ab1'), isNotNull); // too short
    });

    test('confirm password must match', () {
      expect(Validators.confirmPassword('Abcdefg1', 'Abcdefg1'), isNull);
      expect(Validators.confirmPassword('Abcdefg2', 'Abcdefg1'), isNotNull);
    });
  });
}
