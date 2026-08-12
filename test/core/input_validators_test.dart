import 'package:bmi_tracker/core/constants/app_constants.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators.name', () {
    test('rejects empty, short, and overly long names', () {
      expect(InputValidators.name(null), isNotNull);
      expect(InputValidators.name(''), isNotNull);
      expect(InputValidators.name(' '), isNotNull);
      expect(InputValidators.name('A'), isNotNull);
      expect(InputValidators.name('A' * 61), isNotNull);
      expect(InputValidators.name('Rahul'), isNull);
    });
  });

  group('InputValidators.email', () {
    test('rejects invalid emails', () {
      expect(InputValidators.email(null), isNotNull);
      expect(InputValidators.email(''), isNotNull);
      expect(InputValidators.email('not-an-email'), isNotNull);
      expect(InputValidators.email('a@'), isNotNull);
      expect(InputValidators.email('demo@bmitracker.demo'), isNull);
      expect(InputValidators.email('user@example.com'), isNull);
    });
  });

  group('InputValidators.password', () {
    test('rejects empty and short passwords', () {
      expect(InputValidators.password(null), isNotNull);
      expect(InputValidators.password(''), isNotNull);
      expect(
        InputValidators.password('short'),
        contains(AppConstants.passwordMinLength.toString()),
      );
      expect(InputValidators.password('longenough'), isNull);
    });
  });

  group('InputValidators.confirmPassword', () {
    test('rejects empty and mismatched confirmation', () {
      expect(InputValidators.confirmPassword(null, 'password1'), isNotNull);
      expect(InputValidators.confirmPassword('', 'password1'), isNotNull);
      expect(
        InputValidators.confirmPassword('password2', 'password1'),
        'Passwords do not match.',
      );
      expect(InputValidators.confirmPassword('password1', 'password1'), isNull);
    });
  });

  group('InputValidators.weight', () {
    test('rejects invalid kg weights', () {
      expect(InputValidators.weight(null, isLbs: false), isNotNull);
      expect(InputValidators.weight('', isLbs: false), isNotNull);
      expect(InputValidators.weight('abc', isLbs: false), isNotNull);
      expect(InputValidators.weight('10', isLbs: false), isNotNull);
      expect(InputValidators.weight('400', isLbs: false), isNotNull);
      expect(InputValidators.weight('72', isLbs: false), isNull);
    });

    test('rejects invalid lbs weights', () {
      expect(InputValidators.weight('10', isLbs: true), isNotNull);
      expect(InputValidators.weight('700', isLbs: true), isNotNull);
      expect(InputValidators.weight('158.73', isLbs: true), isNull);
    });
  });

  group('InputValidators.height', () {
    test('zero height fails', () {
      expect(InputValidators.height('0', isInches: false), isNotNull);
      expect(InputValidators.height('0', isInches: true), isNotNull);
    });

    test('negative height fails', () {
      expect(InputValidators.height('-1', isInches: false), isNotNull);
      expect(InputValidators.height('-10', isInches: true), isNotNull);
    });

    test('rejects out-of-range and accepts valid', () {
      expect(InputValidators.height('', isInches: false), isNotNull);
      expect(InputValidators.height('abc', isInches: false), isNotNull);
      expect(InputValidators.height('50', isInches: false), isNotNull);
      expect(InputValidators.height('300', isInches: false), isNotNull);
      expect(InputValidators.height('175', isInches: false), isNull);
      expect(InputValidators.height('20', isInches: true), isNotNull);
      expect(InputValidators.height('68.9', isInches: true), isNull);
    });
  });

  group('InputValidators.dateOfBirth', () {
    test('rejects null and future dates', () {
      expect(InputValidators.dateOfBirth(null), isNotNull);
      expect(
        InputValidators.dateOfBirth(
            DateTime.now().add(const Duration(days: 1))),
        isNotNull,
      );
      expect(InputValidators.dateOfBirth(DateTime(1992, 5, 14)), isNull);
    });
  });
}
