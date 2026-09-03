import 'package:flutter_test/flutter_test.dart';
import 'package:travelstories/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), ValidationError.emailRequired);
      expect(Validators.email(null), ValidationError.emailRequired);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), ValidationError.emailInvalid);
      expect(Validators.email('missing@domain'), ValidationError.emailInvalid);
      expect(
        Validators.email('@missing-local.com'),
        ValidationError.emailInvalid,
      );
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('traveler@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty', () {
      expect(Validators.password(''), ValidationError.passwordRequired);
    });

    test('rejects too short', () {
      expect(Validators.password('abc123'), ValidationError.passwordTooShort);
    });

    test('accepts 8+ characters', () {
      expect(Validators.password('abcd1234'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('rejects empty or whitespace-only', () {
      expect(Validators.displayName(''), ValidationError.displayNameRequired);
      expect(
        Validators.displayName('   '),
        ValidationError.displayNameRequired,
      );
    });

    test('accepts a non-empty name', () {
      expect(Validators.displayName('Amina'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects a mismatch', () {
      expect(
        Validators.confirmPassword('abcd1234', 'abcd1235'),
        ValidationError.passwordsDoNotMatch,
      );
    });

    test('accepts a match', () {
      expect(Validators.confirmPassword('abcd1234', 'abcd1234'), isNull);
    });
  });

  group('Validators.title', () {
    test('rejects empty or whitespace-only', () {
      expect(Validators.title(''), ValidationError.titleRequired);
      expect(Validators.title('   '), ValidationError.titleRequired);
    });

    test('rejects over 120 characters', () {
      expect(Validators.title('a' * 121), ValidationError.titleTooLong);
    });

    test('accepts a normal title', () {
      expect(Validators.title('Road trip au Togo'), isNull);
      expect(Validators.title('a' * 120), isNull);
    });
  });

  group('Validators.dateRange', () {
    test('rejects an end date before the start date', () {
      final start = DateTime(2026, 6, 10);
      final end = DateTime(2026, 6, 1);
      expect(
        Validators.dateRange(start, end),
        ValidationError.endDateBeforeStartDate,
      );
    });

    test('accepts a valid range or missing dates', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 10);
      expect(Validators.dateRange(start, end), isNull);
      expect(Validators.dateRange(null, null), isNull);
      expect(Validators.dateRange(start, null), isNull);
      expect(Validators.dateRange(null, end), isNull);
    });
  });
}
