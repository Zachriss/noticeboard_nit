import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../services/auth_service.dart';
import '../shared_preferences/local_storage.dart';

/// Provider for managing user feedback submissions.
/// Features:
/// - Real-time per-user feedback stream via Firestore
/// - Automatic status handling ('pending' by default)
/// - Proper error handling and loading states
/// - Clean resource disposal
class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _feedbackService = FeedbackService();
  final AuthService _authService = AuthService();

  List<FeedbackModel> _feedback = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _feedbackSubscription;

  List<FeedbackModel> get feedback => List.unmodifiable(_feedback);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize provider and set up real-time listener for user's feedback.
  /// Should be called once when the screen initializes.
  void initialize() {
    _setupRealtimeListener();
    // Listen for auth state changes to refresh feedback when user signs in
    _authService.authStateChanges.listen((_) {
      _setupRealtimeListener();
    });
  }

  /// Set up Firestore stream to listen for real-time feedback updates
  /// for the currently authenticated user.
  void _setupRealtimeListener() {
    final user = _authService.currentUser;
    if (user == null) {
      // No authenticated user - show empty feedback with no error
      // The submit form will still be visible
      _feedback = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // Cancel any existing subscription to avoid duplicate listeners
    _feedbackSubscription?.cancel();

    // Set loading state while waiting for initial data
    _isLoading = true;
    notifyListeners();

    // Listen to feedback collection filtered by userId
    _feedbackSubscription = _feedbackService
        .getFeedbackByUser(user.uid)
        .listen(
          (snapshot) {
            _feedback = snapshot;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Manually refresh feedback list (useful for pull-to-refresh).
  /// Performs a one-time fetch and updates the local list.
  Future<void> loadFeedback() async {
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final snapshot = await _feedbackService
            .getFeedbackByUser(user.uid)
            .first;
        _feedback = snapshot;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Submit new feedback to Firestore.
  ///
  /// Includes userId, userName, timestamp, and status='pending' automatically.
  /// Returns true if successful, false otherwise.
  Future<bool> submitFeedback(
    String title,
    String description,
    FeedbackType type,
  ) async {
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      // Get user name from local storage or use email prefix as fallback
      final userName = LocalStorage.userName.isNotEmpty
          ? LocalStorage.userName
          : (user.email?.split('@')[0] ?? 'Anonymous');

      final feedback = FeedbackModel(
        id: '',
        userId: user.uid,
        userName: userName,
        title: title,
        description: description,
        type: type,
        createdAt: DateTime.now(),
        isResolved: false,
        status: 'pending',
      );

      await _feedbackService.createFeedback(feedback);
      // Real-time stream will automatically update the list.
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark feedback as resolved (admin action).
  Future<void> resolveFeedback(String feedbackId) async {
    try {
      await _feedbackService.resolveFeedback(feedbackId);
      // Stream will automatically update the list.
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Update the status of feedback (admin action).
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _feedbackService.updateFeedbackStatus(feedbackId, status);
      // Stream will automatically update the list.
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete feedback (admin or user).
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _feedbackService.deleteFeedback(feedbackId);
      // Stream will automatically update the list.
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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

  void reset() {
    _feedback = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clean up resources when provider is disposed.
  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }
}
