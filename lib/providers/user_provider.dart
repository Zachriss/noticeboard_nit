import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllUsers() async {
    _setLoading(true);
    try {
      _users = _authService.getAllUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> loadAdmins() async {
    _setLoading(true);
    try {
      _users = await _authService.getUsersByRole(UserRole.admin);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveAdmin(String userId) async {
    _setLoading(true);
    try {
      await _authService.approveUser(userId);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isApproved: true);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    _setLoading(true);
    try {
      await _authService.updateUserRole(userId, newRole);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(role: newRole);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String userId) async {
    _setLoading(true);
    try {
      await _authService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}