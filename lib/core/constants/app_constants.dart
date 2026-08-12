/// App-wide constants for BMI Tracker.
class AppConstants {
  AppConstants._();

  static const String appName = 'BMI Tracker';
  static const String companyName = 'IV Innovations Private Limited';
  static const String tagline = 'Understand your progress. Track your health.';

  // Weight ranges
  static const double minWeightKg = 20;
  static const double maxWeightKg = 300;
  static const double minWeightLbs = 44;
  static const double maxWeightLbs = 660;

  // Height ranges
  static const double minHeightCm = 80;
  static const double maxHeightCm = 250;
  static const double minHeightInches = 31;
  static const double maxHeightInches = 98;

  // Conversion constants (precise)
  static const double lbToKg = 0.45359237;
  static const double kgToLb = 1 / lbToKg;
  static const double inchToMeter = 0.0254;
  static const double cmToMeter = 0.01;
  static const double meterToCm = 100;
  static const double inchToCm = 2.54;
  static const double cmToInch = 1 / inchToCm;

  static const int passwordMinLength = 8;

  // Hive box names
  static const String profilesBox = 'profiles_box';
  static const String historyBox = 'history_box';
  static const String settingsBox = 'settings_box';
  static const String syncQueueBox = 'sync_queue_box';

  // Settings keys
  static const String selectedProfileIdKey = 'selected_profile_id';
  static const String themePreferenceKey = 'theme_preference';
  static const String demoModeKey = 'demo_mode';

  static const String demoEmail = 'demo@bmitracker.demo';
}
