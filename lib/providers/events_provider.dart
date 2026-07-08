import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventsProvider extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;

  List<EventModel> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;

  Stream<List<EventModel>> get eventsStream {
    if (_selectedCategory != null) {
      return _eventService.getEventsByCategory(_selectedCategory!);
    }
    return _eventService.getAllEvents();
  }

  Future<void> loadEvents() async {
    _setLoading(true);
    try {
      final stream = eventsStream;
      _events = await stream.first;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
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

  void reset() {
    _events = [];
    _isLoading = false;
    _errorMessage = null;
    _selectedCategory = null;
    notifyListeners();
  }
}
