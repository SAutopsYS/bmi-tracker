/// Centralized English UI strings for localization readiness.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'BMI Tracker';
  static const String companyName = 'IV Innovations Private Limited';
  static const String tagline = 'Understand your progress. Track your health.';

  // Auth
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle =
      'Sign in to continue tracking your health.';
  static const String registerTitle = 'Create account';
  static const String registerSubtitle = 'Start your health journey today.';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String nameLabel = 'Full name';
  static const String signIn = 'Sign in';
  static const String signUp = 'Sign up';
  static const String signOut = 'Sign out';
  static const String forgotPassword = 'Forgot password?';
  static const String forgotPasswordTitle = 'Reset password';
  static const String forgotPasswordSubtitle =
      'Enter your email and we will send a reset link.';
  static const String sendResetLink = 'Send reset link';
  static const String resetEmailSent =
      'Password reset email sent. Check your inbox.';
  static const String continueWithGoogle = 'Continue with Google';
  static const String noAccount = 'Do not have an account?';
  static const String haveAccount = 'Already have an account?';
  static const String demoSignIn = 'Try Demo';

  // Profile setup
  static const String profileSetupTitle = 'Set up your profile';
  static const String profileSetupSubtitle =
      'Add your details so we can calculate BMI accurately.';
  static const String saveProfile = 'Save profile';
  static const String continueLabel = 'Continue';

  // Dashboard
  static const String dashboardTitle = 'Dashboard';
  static const String currentBmi = 'Current BMI';
  static const String weightLabel = 'Weight';
  static const String heightLabel = 'Height';
  static const String bmiCategory = 'Category';
  static const String sevenDayStats = '7-day overview';
  static const String logWeight = 'Log weight';
  static const String weightChange = 'Weight change';
  static const String bmiChange = 'BMI change';
  static const String selectProfile = 'Select profile';

  // Profiles
  static const String profilesTitle = 'Profiles';
  static const String addProfile = 'Add profile';
  static const String editProfile = 'Edit profile';
  static const String deleteProfile = 'Delete profile';
  static const String primaryProfile = 'Primary';
  static const String genderLabel = 'Gender';
  static const String dateOfBirthLabel = 'Date of birth';
  static const String setAsPrimary = 'Set as primary';
  static const String profileSaved = 'Profile saved.';
  static const String profileDeleted = 'Profile deleted.';

  // History
  static const String historyTitle = 'History';
  static const String noHistory = 'No weight history yet.';
  static const String noHistoryHint = 'Log a weight entry from the dashboard.';
  static const String deleteEntry = 'Delete entry';
  static const String entryDeleted = 'Entry deleted.';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String themeLabel = 'Theme';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String unitsLabel = 'Units';
  static const String exportData = 'Export data';
  static const String exportCsv = 'Export as CSV';
  static const String privacyNote =
      'This app is designed for personal health tracking and does not replace '
      'professional medical advice. Your health data stays private to your account.';
  static const String aboutApp = 'About';
  static const String versionLabel = 'Version';
  static const String offlineMode = 'Offline mode';
  static const String localDemoMode = 'Local Demo Mode';
  static const String syncPending = 'Changes waiting to sync';
  static const String cloudUnavailable =
      'Cloud sync unavailable until Firebase is configured.';

  // Export
  static const String exportTitle = 'Export';
  static const String exportSuccess = 'Export ready to share.';
  static const String exportEmpty = 'Nothing to export yet.';

  // Empty states
  static const String noProfiles =
      'No profiles yet. Create one to start tracking.';
  static const String emptyDashboard =
      'Add a profile and log your first weight to see insights.';

  // Errors
  static const String errorGeneric =
      'Unable to complete that action. Please try again.';
  static const String resetDemoData = 'Reset demo data';
  static const String resetDemoDataHint =
      'Restore Rahul and Priya sample profiles on this device. Local demo mode only.';
  static const String errorNetwork =
      'No internet connection. Changes will sync when you are back online.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorValidation =
      'Please check your input and try again.';
  static const String errorStorage = 'Could not save data locally.';
  static const String requiredField = 'This field is required.';

  // Common
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String done = 'Done';
  static const String kg = 'kg';
  static const String lbs = 'lbs';
  static const String cm = 'cm';
  static const String inches = 'in';
}
