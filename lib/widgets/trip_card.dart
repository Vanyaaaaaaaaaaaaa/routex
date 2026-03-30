import 'package:flutter/material.dart';
import '../services/trip_service.dart';
import '../screens/trip_details_page.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? docId;
  final bool showButton;
  final bool showOnlyFreeUp;

  const TripCard({
    super.key,
    required this.data,
    this.docId,
    this.showButton = true,
    this.showOnlyFreeUp = false,
  });

  String _formatDate(String dateStr) {
    try {
      if (!dateStr.contains("AM") && !dateStr.contains("PM")) return dateStr;

      final parts = dateStr.split(" • ");
      if (parts.length != 2) return dateStr;

      final datePart = parts[0];
      final timePart = parts[1].trim();

      final timeMatch = RegExp(r"(\d{1,2}):(\d{2})\s*(AM|PM)", caseSensitive: false)
          .firstMatch(timePart);
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
    return GestureDetector(
      onTap: () {
        if (docId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailsPage(
                data: data,
                docId: docId!,
                showOnlyFreeUp: showOnlyFreeUp,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                    const Icon(Icons.location_on, color: Colors.black, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${data['from']} → ${data['to']}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${data['price']} ₴",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
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
                        size: 18, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(data['date'].toString()),
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chair_alt, size: 18, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      "${data['seats']} місць",
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),

                if (showButton) ...[
                  const SizedBox(height: 16),

                  /// ===== BUTTON =====
                  StreamBuilder<bool>(
                    stream: docId != null
                        ? TripService.checkIfJoined(docId!)
                        : Stream.value(false),
                    builder: (context, snapshot) {
                      final joined = snapshot.data ?? false;

                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                joined ? Colors.redAccent.withOpacity(0.1) : Colors.black,
                            foregroundColor:
                                joined ? Colors.redAccent : Colors.white,
                            elevation: 0,
                            side: joined ? const BorderSide(color: Colors.redAccent, width: 1) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            if (docId != null) {
                              try {
                                if (joined) {
                                  // Скасувати
                                  await TripService.leaveTrip(docId!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Місце звільнено ✔")),
                                    );
                                  }
                                } else {
                                  // Приєднатися
                                  await TripService.joinTrip(docId!, data);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Ви приєдналися до поїздки! 🚗")),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll("Exception: ", "")),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Text(
                            joined ? "Звільнити місце" : "Приєднатися",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
