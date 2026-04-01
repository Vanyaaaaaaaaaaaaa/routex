import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ➤ Додати поїздку
  static Future<void> addTrip({
    required String from,
    required String to,
    required DateTime dateTime,
    required int seats,
    required String price,
    String? comment,
    double? lat, // Координати
    double? lng,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('trips').add({
      'from': from,
      'to': to,
      'dateTime': Timestamp.fromDate(dateTime),
      'date': "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
      'seats': seats,
      'price': price,
      'comment': comment,
      'lat': lat,
      'lng': lng,
      'driverId': user.uid,
      'driver': user.displayName ?? 'Водій',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ➤ Всі поїздки (тільки майбутні)
  static Stream<QuerySnapshot> allTrips() {
    return _firestore
        .collection('trips')
        .where('dateTime', isGreaterThan: Timestamp.now()) // Фільтрація минулих
        .orderBy('dateTime', descending: false) // Найближчі спочатку
        .snapshots();
  }

  // ➤ Отримати одну поїздку (стрім)
  static Stream<DocumentSnapshot> getTripStream(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots();
  }

  // ➤ Мої поїздки (і водія, і пасажира)
  static Stream<QuerySnapshot> myTrips() {
    final user = _auth.currentUser;
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: user?.uid)
        .orderBy('dateTime', descending: false)
        .snapshots();
  }

  // ➤ ЧАТ: Відправити повідомлення
  static Future<void> sendMessage(String tripId, String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Користувач',
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  // ➤ ЧАТ: Отримати повідомлення
  static Stream<QuerySnapshot> getMessages(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
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

  // ➤ Скинути та додати тестові дані
  static Future<void> seedData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Видаляємо існуючі поїздки (щоб не дублювати при кожному натисканні)
    final snapshot = await _firestore.collection('trips').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // 2. Додаємо нові цікаві маршрути
    final now = DateTime.now();
    final trips = [
      {
        'from': 'Київ',
        'to': 'Львів',
        'dateTime': now.add(const Duration(days: 2, hours: 8)),
        'seats': 3,
        'price': '450',
        'comment': 'Комфортне авто, виїзд від метро Житомирська.',
        'lat': 50.4554,
        'lng': 30.3649,
      },
      {
        'from': 'Одеса',
        'to': 'Київ',
        'dateTime': now.add(const Duration(days: 1, hours: 10)),
        'seats': 2,
        'price': '550',
        'comment': 'Їду через Умань, можу підібрати по дорозі.',
        'lat': 46.4825,
        'lng': 30.7233,
      },
      {
        'from': 'Дніпро',
        'to': 'Харків',
        'dateTime': now.add(const Duration(days: 3, hours: 14)),
        'seats': 4,
        'price': '300',
        'comment': 'Великий багажник, можна з сумками.',
        'lat': 48.4647,
        'lng': 35.0462,
      },
      {
        'from': 'Львів',
        'to': 'Івано-Франківськ',
        'dateTime': now.add(const Duration(days: 4, hours: 9)),
        'seats': 4,
        'price': '200',
        'comment': 'Швидка поїздка, без затримок.',
        'lat': 49.8397,
        'lng': 24.0297,
      },
      {
        'from': 'Київ',
        'to': 'Чернігів',
        'dateTime': now.add(const Duration(days: 0, hours: 18)),
        'seats': 3,
        'price': '150',
        'comment': 'Виїзд ввечері, метро Лісова.',
        'lat': 50.4651,
        'lng': 30.6454,
      },
      {
        'from': 'Полтава',
        'to': 'Київ',
        'dateTime': now.add(const Duration(days: 2, hours: 7)),
        'seats': 1,
        'price': '350',
        'comment': 'В машині не курять. Дуже комфортно.',
        'lat': 49.5883,
        'lng': 34.5514,
      },
      {
        'from': 'Тернопіль',
        'to': 'Рівне',
        'dateTime': now.add(const Duration(days: 5, hours: 12)),
        'seats': 2,
        'price': '180',
        'comment': 'Приємна музика в дорозі.',
        'lat': 49.5535,
        'lng': 25.5948,
      },
      {
        'from': 'Вінниця',
        'to': 'Одеса',
        'dateTime': now.add(const Duration(days: 3, hours: 6)),
        'seats': 3,
        'price': '400',
        'comment': 'Зупинка на каву за бажанням.',
        'lat': 49.2328,
        'lng': 28.4800,
      },
      {
        'from': 'Київ',
        'to': 'Буковель',
        'dateTime': now.add(const Duration(days: 6, hours: 23)),
        'seats': 6,
        'price': '800',
        'comment': 'Мікроавтобус, беремо лижі/борди!',
        'lat': 50.4501,
        'lng': 30.5234,
      },
      {
        'from': 'Чернівці',
        'to': 'Львів',
        'dateTime': now.add(const Duration(days: 1, hours: 15)),
        'seats': 3,
        'price': '280',
        'comment': 'Досвідчений водій, безпека понад усе.',
        'lat': 48.2917,
        'lng': 25.9352,
      },
    ];

    for (var trip in trips) {
      await addTrip(
        from: trip['from'] as String,
        to: trip['to'] as String,
        dateTime: trip['dateTime'] as DateTime,
        seats: trip['seats'] as int,
        price: trip['price'] as String,
        comment: trip['comment'] as String,
        lat: trip['lat'] as double?,
        lng: trip['lng'] as double?,
      );
    }
  }
}
