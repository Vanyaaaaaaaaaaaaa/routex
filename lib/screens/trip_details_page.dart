import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/trip_service.dart';
import 'chat_page.dart';

class TripDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool showOnlyFreeUp;

  const TripDetailsPage({
    super.key,
    required this.data,
    required this.docId,
    this.showOnlyFreeUp = false,
  });

  String _formatDate(String dateStr) {
    try {
      if (!dateStr.contains("AM") && !dateStr.contains("PM")) return dateStr;
      final parts = dateStr.split(" • ");
      if (parts.length != 2) return dateStr;
      final datePart = parts[0];
      final timePart = parts[1].trim();
      final timeMatch = RegExp(r"(\d{1,2}):(\d{2})\s*(AM|PM)", caseSensitive: false).firstMatch(timePart);
      if (timeMatch == null) return dateStr;
      int hour = int.parse(timeMatch.group(1)!);
      final minute = timeMatch.group(2)!;
      final period = timeMatch.group(3)!.toUpperCase();
      if (period == "PM" && hour < 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      final newHour = hour.toString().padLeft(2, '0');
      return "$datePart • $newHour:$minute";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDriver = data['driverId'] == user?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Деталі поїздки"),
        actions: [
          StreamBuilder<bool>(
            stream: TripService.checkIfJoined(docId),
            builder: (context, snapshot) {
              final joined = snapshot.data ?? false;
              if (isDriver || joined) {
                return IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          tripId: docId,
                          tripName: "${data['from']} → ${data['to']}",
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: TripService.getTripStream(docId),
        builder: (context, tripSnapshot) {
          if (!tripSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final liveData = tripSnapshot.data!.data() as Map<String, dynamic>?;
          if (liveData == null) {
            return const Center(child: Text("Поїздку не знайдено 😕"));
          }

          final driver = liveData['driver'] ?? 'Водій';
          final from = liveData['from'];
          final to = liveData['to'];
          final date = liveData['date'];
          final seats = liveData['seats'];
          final price = liveData['price'];
          final comment = liveData['comment'];
          final double? lat = liveData['lat'];
          final double? lng = liveData['lng'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Маршрут
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: Colors.black, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "$from → $to",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _infoRow(context, Icons.calendar_month_outlined, "Дата:", _formatDate(date.toString())),
                _infoRow(context, Icons.airline_seat_recline_normal_outlined, "Вільних місць:", "$seats"),
                _infoRow(context, Icons.price_check_outlined, "Ціна:", "$price ₴/місце"),

                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.comment_outlined, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text("Коментар водія:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Карта з міткою (FLUTTER MAP)
                if (lat != null && lng != null) ...[
                  const Text("Місце збору", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.routex',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng),
                                width: 50,
                                height: 50,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Водій
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: Colors.black.withOpacity(0.05), child: const Icon(Icons.person, color: Colors.black, size: 34)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
                          const Text("Водій", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Пасажири
                if (isDriver) ...[
                  const Text("Пасажири", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('trips').doc(docId).collection('bookings').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.black);
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Text("Пасажирів ще немає 😕", style: TextStyle(color: Colors.grey));
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final p = docs[i].data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: Colors.black.withOpacity(0.05), child: const Icon(Icons.person_outline, color: Colors.black54)),
                            title: Text(p['userName'] ?? 'Анонім', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                            subtitle: const Text("Забронював місце", style: TextStyle(color: Colors.black45, fontSize: 13)),
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 40),

                // Кнопка Бронювання
                if (!isDriver)
                  StreamBuilder<bool>(
                    stream: TripService.checkIfJoined(docId),
                    builder: (context, snapshot) {
                      final joined = snapshot.data ?? false;
                      if (showOnlyFreeUp && !joined) return const SizedBox.shrink();
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: joined ? Colors.redAccent.withOpacity(0.1) : Colors.black,
                            foregroundColor: joined ? Colors.redAccent : Colors.white,
                            side: joined ? const BorderSide(color: Colors.redAccent, width: 1) : null,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            try {
                              if (joined) {
                                await TripService.leaveTrip(docId);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Місце звільнено ✔")));
                              } else {
                                await TripService.joinTrip(docId, liveData);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ви приєдналися до поїздки! 🚗")));
                              }
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent));
                            }
                          },
                          child: Text(joined ? "Звільнити місце" : "Забронювати місце", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      );
                    },
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 22),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
        ],
      ),
    );
  }
}
