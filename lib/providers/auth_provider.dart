import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.loginWithEmail(email: email, password: password);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> register(UserModel user, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.registerUser(user: user, password: password);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
    }
    notifyListeners();
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