import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String keyIsFirstLaunch = 'isFirstLaunch';
  static const String keyUserRole = 'userRole';
  static const String keyUserName = 'userName';
  static const String keyUserDepartment = 'userDepartment';
  static const String keyUserYear = 'userYear';
  static const String keyUserPhone = 'userPhone';
  static const String keyIsProfileSetup = 'isProfileSetup';

  // First launch check
  static bool get isFirstLaunch => _prefs?.getBool(keyIsFirstLaunch) ?? true;
  static Future<void> setFirstLaunch(bool value) async {
    await _prefs?.setBool(keyIsFirstLaunch, value);
  }

  // User Role (student/admin/super_admin)
  static String get userRole => _prefs?.getString(keyUserRole) ?? 'student';
  static Future<void> setUserRole(String role) async {
    await _prefs?.setString(keyUserRole, role);
  }

  // Profile Data
  static String get userName => _prefs?.getString(keyUserName) ?? '';
  static Future<void> setUserName(String name) async {
    await _prefs?.setString(keyUserName, name);
  }

  static String get userDepartment =>
      _prefs?.getString(keyUserDepartment) ?? '';
  static Future<void> setUserDepartment(String dept) async {
    await _prefs?.setString(keyUserDepartment, dept);
  }

  static String get userYear => _prefs?.getString(keyUserYear) ?? '';
  static Future<void> setUserYear(String year) async {
    await _prefs?.setString(keyUserYear, year);
  }

  static String get userPhone => _prefs?.getString(keyUserPhone) ?? '';
  static Future<void> setUserPhone(String phone) async {
    await _prefs?.setString(keyUserPhone, phone);
  }

  // Profile Setup Status
  static bool get isProfileSetup => _prefs?.getBool(keyIsProfileSetup) ?? false;
  static Future<void> setProfileSetup(bool value) async {
    await _prefs?.setBool(keyIsProfileSetup, value);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
