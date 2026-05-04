class AppStrings {
  // App
  static const String appName = 'NIT Notice Board';
  static const String appTagline = 'Your Campus Notice Hub';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String logout = 'Logout';

  // Roles
  static const String student = 'Student';
  static const String admin = 'Admin';
  static const String superAdmin = 'Super Admin';

  // Navigation
  static const String home = 'Home';
  static const String notices = 'Notices';
  static const String profile = 'Profile';
  static const String settings = 'Settings';

  // Notices
  static const String createNotice = 'Create Notice';
  static const String editNotice = 'Edit Notice';
  static const String deleteNotice = 'Delete Notice';
  static const String noticeTitle = 'Title';
  static const String noticeDescription = 'Description';
  static const String noticeCategory = 'Category';
  static const String noticeImage = 'Image';

  // Categories
  static const List<String> categories = [
    'Academic',
    'Exams',
    'Events',
    'Library',
    'Placement',
    'Sports',
    'General',
  ];

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String update = 'Update';
  static const String submit = 'Submit';

  // Messages
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String error = 'Something went wrong';
  static const String success = 'Success';
  static const String confirmDelete = 'Are you sure you want to delete?';

  // Validation
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
}
