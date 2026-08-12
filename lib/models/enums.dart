/// Shared domain enums for BMI Tracker.
enum Gender {
  male('Male'),
  female('Female'),
  other('Other'),
  preferNotToSay('Prefer not to say');

  const Gender(this.label);
  final String label;

  static Gender fromString(String? value) {
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}

enum WeightUnit {
  kg('kg'),
  lbs('lbs');

  const WeightUnit(this.label);
  final String label;

  bool get isLbs => this == WeightUnit.lbs;

  static WeightUnit fromString(String? value) {
    return WeightUnit.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => WeightUnit.kg,
    );
  }
}

enum HeightUnit {
  cm('cm'),
  inches('in');

  const HeightUnit(this.label);
  final String label;

  bool get isInches => this == HeightUnit.inches;

  static HeightUnit fromString(String? value) {
    return HeightUnit.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => HeightUnit.cm,
    );
  }
}

enum ThemePreference {
  system('System'),
  light('Light'),
  dark('Dark');

  const ThemePreference(this.label);
  final String label;

  static ThemePreference fromString(String? value) {
    return ThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemePreference.system,
    );
  }
}

enum SyncStatus {
  synced,
  pending,
  failed;

  static SyncStatus fromString(String? value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
