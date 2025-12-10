import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ➤ Додати поїздку
  static Future<void> addTrip({
    required String from,
    required String to,
    required String date,
    required int seats,
    required String price,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('trips').add({
      'from': from,
      'to': to,
      'date': date,
      'seats': seats,
      'price': price,
      'driverId': user.uid,
      'driver': user.displayName ?? 'Водій',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ➤ Всі поїздки
  static Stream<QuerySnapshot> allTrips() {
    return _firestore
        .collection('trips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ➤ Мої поїздки
  static Stream<QuerySnapshot> myTrips() {
    final user = _auth.currentUser;
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ➤ Видалити поїздку
  static Future<void> deleteTrip(String id) async {
    await _firestore.collection('trips').doc(id).delete();
  }
}
