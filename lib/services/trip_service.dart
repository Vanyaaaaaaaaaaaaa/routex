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
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('trips').add({
      'from': from,
      'to': to,
      'date': date,
      'seats': seats,
      'price': price,
      'comment': comment,
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

  // ➤ Отримати одну поїздку (стрім)
  static Stream<DocumentSnapshot> getTripStream(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots();
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

  // ➤ Кількість поїздок як водія
  static Future<int> getDriverTripCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final snap = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: user.uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ➤ Кількість поїздок як пасажира
  static Future<int> getPassengerTripCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final snap = await _firestore
        .collectionGroup('bookings')
        .where('userId', isEqualTo: user.uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ➤ Приєднатися до поїздки
  static Future<void> joinTrip(String tripId, Map<String, dynamic> tripData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final tripDocRef = _firestore.collection('trips').doc(tripId);
    final tripSnapshot = await tripDocRef.get();

    if (!tripSnapshot.exists) return;

    final currentSeats = tripSnapshot.data()?['seats'] ?? 0;
    if (currentSeats <= 0) {
      throw Exception("Вибачте, вільних місць більше немає 😕");
    }

    final bookingData = {
      'userId': user.uid,
      'tripId': tripId,
      'userName': user.displayName ?? 'Пасажир',
      'bookedAt': FieldValue.serverTimestamp(),
      ...tripData,
    };

    // Використовуємо транзакцію або пакетне оновлення для надійності
    final batch = _firestore.batch();

    // 1. Для водія (у підколекцію поїздки)
    batch.set(
      tripDocRef.collection('bookings').doc(user.uid),
      bookingData,
    );

    // 2. Для пасажира (у глобальну колекцію)
    batch.set(
      _firestore.collection('bookings').doc("${user.uid}_$tripId"),
      bookingData,
    );

    // 3. Зменшуємо кількість місць у самій поїздці
    batch.update(tripDocRef, {'seats': FieldValue.increment(-1)});

    await batch.commit();
  }

  // ➤ Скасувати бронювання (звільнити місце)
  static Future<void> leaveTrip(String tripId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final tripDocRef = _firestore.collection('trips').doc(tripId);
    final batch = _firestore.batch();

    // 1. Видаляємо у водія
    batch.delete(tripDocRef.collection('bookings').doc(user.uid));

    // 2. Видаляємо у пасажира
    batch.delete(_firestore.collection('bookings').doc("${user.uid}_$tripId"));

    // 3. Збільшуємо кількість місць
    batch.update(tripDocRef, {'seats': FieldValue.increment(1)});

    await batch.commit();
  }

  // ➤ Перевірити, чи я вже приєднався
  static Stream<bool> checkIfJoined(String tripId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    
    return _firestore
        .collection('bookings')
        .doc("${user.uid}_$tripId")
        .snapshots()
        .map((doc) => doc.exists);
  }
}
