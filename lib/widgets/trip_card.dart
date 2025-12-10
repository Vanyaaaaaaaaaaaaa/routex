import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? docId;

  const TripCard({
    super.key,
    required this.data,
    this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 14,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ===== FROM → TO =====
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${data['from']} → ${data['to']}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${data['price']} ₴",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A66FF),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ===== DATE + SEATS =====
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    data['date'].toString(),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.chair, size: 18, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    "${data['seats']} місць",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// ===== BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Скоро буде! 🚀")),
                    );
                  },
                  child: const Text(
                    "Запросити місце",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
