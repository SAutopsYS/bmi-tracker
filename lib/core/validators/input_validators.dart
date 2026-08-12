import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

/// Form validators returning friendly [String?] error messages.
class InputValidators {
  InputValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a name.';
    if (trimmed.length < 2) return 'Name should be at least 2 characters.';
    if (trimmed.length > 60) return 'Name is too long.';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter your email.';
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter a password.';
    if (text.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please confirm your password.';
    if (text != (password ?? '')) return 'Passwords do not match.';
    return null;
  }

  static String? weight(
    String? value, {
    required bool isLbs,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a weight.';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid number for weight.';
    if (isLbs) {
      if (parsed < AppConstants.minWeightLbs ||
          parsed > AppConstants.maxWeightLbs) {
        return 'Weight should be between ${AppConstants.minWeightLbs.toInt()} and ${AppConstants.maxWeightLbs.toInt()} ${AppStrings.lbs}.';
      }
    } else {
      if (parsed < AppConstants.minWeightKg ||
          parsed > AppConstants.maxWeightKg) {
        return 'Weight should be between ${AppConstants.minWeightKg.toInt()} and ${AppConstants.maxWeightKg.toInt()} ${AppStrings.kg}.';
      }
    }
    return null;
  }

  static String? height(
    String? value, {
    required bool isInches,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a height.';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid number for height.';
    if (isInches) {
      if (parsed < AppConstants.minHeightInches ||
          parsed > AppConstants.maxHeightInches) {
        return 'Height should be between ${AppConstants.minHeightInches.toInt()} and ${AppConstants.maxHeightInches.toInt()} ${AppStrings.inches}.';
      }
    } else {
      if (parsed < AppConstants.minHeightCm ||
          parsed > AppConstants.maxHeightCm) {
        return 'Height should be between ${AppConstants.minHeightCm.toInt()} and ${AppConstants.maxHeightCm.toInt()} ${AppStrings.cm}.';
      }
    }
    return null;
  }

  static String? date(DateTime? value, {String fieldName = 'date'}) {
    if (value == null) return 'Please select a $fieldName.';
    final now = DateTime.now();
    if (value.isAfter(now)) return 'Date cannot be in the future.';
    return null;
  }

  static String? dateOfBirth(DateTime? value) {
    if (value == null) return 'Please select a date of birth.';
    final now = DateTime.now();
    if (value.isAfter(now)) return 'Date of birth cannot be in the future.';
    final minDate = DateTime(now.year - 120, now.month, now.day);
    if (value.isBefore(minDate)) return 'Please enter a valid date of birth.';
    return null;
  }
}
