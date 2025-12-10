import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/trip_card.dart';
import 'add_trip_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  int selectedTab = 0; // 0 — Я водій, 1 — Я пасажир

  Stream<QuerySnapshot> _driverTrips() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _passengerBookings() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collectionGroup('bookings')
        .where("userId", isEqualTo: user?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4FA),
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Мої поїздки",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Таби "Я водій / Я пасажир"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tabButton("Я водій", 0),
                  _tabButton("Я пасажир", 1),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Список поїздок / бронювань
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    selectedTab == 0 ? _driverTrips() : _passengerBookings(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Поки немає поїздок"),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;

                      final docId = docs[i].id;
                      data['id'] = docId;

                      return TripCard(
                        data: data,
                        docId: docId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Плаваюча кнопка + тільки для "Я водій"
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF007BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add, size: 32),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTripPage(),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _tabButton(String title, int tab) {
    final bool active = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF007BFF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
