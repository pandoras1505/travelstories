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
      expect(Validators.email('@missing-local.com'), ValidationError.emailInvalid);
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
      expect(Validators.displayName('   '), ValidationError.displayNameRequired);
    });

    test('accepts a non-empty name', () {
      expect(Validators.displayName('Amina'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects a mismatch', () {
      expect(Validators.confirmPassword('abcd1234', 'abcd1235'), ValidationError.passwordsDoNotMatch);
    });

    test('accepts a match', () {
      expect(Validators.confirmPassword('abcd1234', 'abcd1234'), isNull);
    });
  });
}
