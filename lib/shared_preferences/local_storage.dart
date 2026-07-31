import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorage {
  static SharedPreferences? _prefs;
  static const String _deviceIdKey = 'deviceId';
  static final Uuid _uuid = Uuid();

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
  static const String keyNotificationsEnabled = 'notificationsEnabled';
  static const String keyLastViewedNoticeTime = 'lastViewedNoticeTime';
  static const String keyNotificationSoundEnabled = 'notificationSoundEnabled';
  static const String keyProfileImage = 'profileImage';

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

  static bool get notificationEnabled =>
      _prefs?.getBool(keyNotificationsEnabled) ?? true;
  static Future<void> setNotificationEnabled(bool value) async {
    await _prefs?.setBool(keyNotificationsEnabled, value);
  }

  static bool get notificationSoundEnabled =>
      _prefs?.getBool(keyNotificationSoundEnabled) ?? true;
  static Future<void> setNotificationSoundEnabled(bool value) async {
    await _prefs?.setBool(keyNotificationSoundEnabled, value);
  }

  // Profile Image (base64 encoded)
  static String get profileImage => _prefs?.getString(keyProfileImage) ?? '';
  static Future<void> setProfileImage(String base64) async {
    await _prefs?.setString(keyProfileImage, base64);
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

  // Last viewed notice timestamp (ISO8601 string)
  static DateTime? get lastViewedNoticeTime {
    final value = _prefs?.getString(keyLastViewedNoticeTime);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> setLastViewedNoticeTime(DateTime? time) async {
    if (time == null) {
      await _prefs?.remove(keyLastViewedNoticeTime);
    } else {
      await _prefs?.setString(keyLastViewedNoticeTime, time.toIso8601String());
    }
  }

  // Save student profile
  static Future<void> saveStudentProfile({
    required String name,
    required String department,
    required String year,
    String? phone,
  }) async {
    await setUserName(name);
    await setUserDepartment(department);
    await setUserYear(year);
    if (phone != null) {
      await setUserPhone(phone);
    }
    await setProfileSetup(true);
  }

  // Device identifier for anonymous likes
  static Future<String> getDeviceId() async {
    _prefs ??= await SharedPreferences.getInstance();
    var deviceId = _prefs?.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _prefs?.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
