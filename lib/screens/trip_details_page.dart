import 'package:flutter/material.dart';

class TripDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const TripDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final driver = data['driver'] ?? 'Водій';
    final from = data['from'];
    final to = data['to'];
    final date = data['date'];
    final seats = data['seats'];
    final price = data['price'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Деталі поїздки"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Маршрут
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "$from → $to",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _infoRow(Icons.calendar_month, "Дата:", date),
            _infoRow(
                Icons.airline_seat_recline_normal, "Вільних місць:", "$seats"),
            _infoRow(Icons.price_check, "Ціна:", "$price ₴/місце"),

            const SizedBox(height: 24),

            // Водій
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.orange, size: 20),
                        Text("4.9",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                )
              ],
            ),

            const Spacer(),

            // Бронювання
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Запит відправлено водію ✔")));
                },
                child: const Text(
                  "Запросити місце",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
