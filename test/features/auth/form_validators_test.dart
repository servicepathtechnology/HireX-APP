import 'package:flutter_test/flutter_test.dart';
import 'package:hirex_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });
    test('returns error for empty', () {
      expect(Validators.email(''), isNotNull);
    });
    test('returns error for invalid format', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for strong password', () {
      expect(Validators.password('Secure@123'), isNull);
    });
    test('returns error for too short', () {
      expect(Validators.password('Ab1!'), isNotNull);
    });
    test('returns error for no uppercase', () {
      expect(Validators.password('secure@123'), isNotNull);
    });
    test('returns error for no number', () {
      expect(Validators.password('Secure@abc'), isNotNull);
    });
    test('returns error for no special char', () {
      expect(Validators.password('Secure123'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('Secure@123', 'Secure@123'), isNull);
    });
    test('returns error when passwords do not match', () {
      expect(Validators.confirmPassword('Secure@123', 'Different@1'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('returns null for valid name', () {
      expect(Validators.fullName('John Doe'), isNull);
    });
    test('returns error for single char', () {
      expect(Validators.fullName('J'), isNotNull);
    });
    test('returns error for empty', () {
      expect(Validators.fullName(''), isNotNull);
    });
  });

  group('Validators.passwordStrength', () {
    test('returns 0 for weak password', () {
      expect(Validators.passwordStrength('abc'), 0);
    });
    test('returns 1 for medium password', () {
      expect(Validators.passwordStrength('Secure1'), 1);
    });
    test('returns >= 2 for strong password', () {
      expect(Validators.passwordStrength('Secure@123456'), greaterThanOrEqualTo(2));
    });
  });
}
