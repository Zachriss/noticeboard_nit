import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_collections.dart';
import '../models/faq_model.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FAQModel> _sortByOrder(List<FAQModel> list) {
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<List<FAQModel>> getAllFAQs() async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .get();

    return _sortByOrder(
      snapshot.docs
          .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Stream<List<FAQModel>> getFAQsStream() {
    // Use a single-field filter only (no orderBy) to avoid requiring a
    // composite index on (isActive, order). Sort client-side instead.
    return _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => _sortByOrder(
              snapshot.docs
                  .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
                  .toList(),
            ));
  }

  // Stream of ALL FAQs (active + inactive) for admin management.
  // Plain collection stream — no composite index required.
  Stream<List<FAQModel>> getAllFaqsStream() {
    return _firestore
        .collection(FirebaseCollections.faqs)
        .snapshots()
        .map((snapshot) => _sortByOrder(
              snapshot.docs
                  .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
                  .toList(),
            ));
  }

  Future<List<FAQModel>> getFAQsByCategory(String category) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .get();

    return _sortByOrder(
      snapshot.docs
          .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> createFAQ(FAQModel faq) async {
    final docRef = _firestore.collection(FirebaseCollections.faqs).doc();
    final newFAQ = faq.copyWith(id: docRef.id);
    await docRef.set(newFAQ.toMap());
  }

  Future<void> updateFAQ(FAQModel faq) async {
    await _firestore
        .collection(FirebaseCollections.faqs)
        .doc(faq.id)
        .update(faq.toMap());
  }

  Future<void> deleteFAQ(String faqId) async {
    await _firestore.collection(FirebaseCollections.faqs).doc(faqId).delete();
  }
}