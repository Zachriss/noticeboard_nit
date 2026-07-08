import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../core/services/firebase_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all upcoming events
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection(FirebaseService.eventsCollection)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection(FirebaseService.eventsCollection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get single event
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseService.eventsCollection)
          .doc(eventId)
          .get();

      if (!doc.exists) return null;
      return EventModel.fromMap(doc.data()!, eventId);
    } catch (e) {
      return null;
    }
  }

  // Create event (admin only)
  Future<String> createEvent(EventModel event) async {
    final docRef = _firestore
        .collection(FirebaseService.eventsCollection)
        .doc();
    await docRef.set(event.copyWith(id: docRef.id).toMap());
    return docRef.id;
  }

  // Update event (admin only)
  Future<void> updateEvent(EventModel event) async {
    await _firestore
        .collection(FirebaseService.eventsCollection)
        .doc(event.id)
        .update(event.toMap());
  }

  // Delete event (admin only)
  Future<void> deleteEvent(String eventId) async {
    await _firestore
        .collection(FirebaseService.eventsCollection)
        .doc(eventId)
        .delete();
  }
}
