import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_collections.dart';
import '../models/faq_model.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FAQModel>> getAllFAQs() async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<FAQModel>> getFAQsStream() {
    return _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<FAQModel>> getFAQsByCategory(String category) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.faqs)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('order', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => FAQModel.fromMap(doc.data(), doc.id))
        .toList();
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