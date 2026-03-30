import 'package:flutter/material.dart';
import '../services/trip_service.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final seatsController = TextEditingController();
  final priceController = TextEditingController();
  final commentController = TextEditingController();

  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );

    if (date != null) {
      dateController.text = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      timeController.text = "$hour:$minute";
    }
  }

  Future<void> createTrip() async {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        seatsController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заповніть усі поля")),
      );
      return;
    }

    await TripService.addTrip(
      from: fromController.text.trim(),
      to: toController.text.trim(),
      date: "${dateController.text} • ${timeController.text}",
      seats: int.parse(seatsController.text),
      price: priceController.text.trim(),
      comment: commentController.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Поїздку створено ✔")),
    );
  }

  Widget field({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54, size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Нова поїздка",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              field(
                icon: Icons.location_on_outlined,
                hint: "Звідки",
                controller: fromController,
              ),
              field(
                icon: Icons.flag_outlined,
                hint: "Куди",
                controller: toController,
              ),
              field(
                icon: Icons.calendar_today_outlined,
                hint: "Дата",
                controller: dateController,
                readOnly: true,
                onTap: pickDate,
              ),
              field(
                icon: Icons.access_time_outlined,
                hint: "Час",
                controller: timeController,
                readOnly: true,
                onTap: pickTime,
              ),
              field(
                icon: Icons.chair_outlined,
                hint: "Кількість місць",
                controller: seatsController,
                keyboardType: TextInputType.number,
              ),
              field(
                icon: Icons.attach_money_outlined,
                hint: "Ціна (грн)",
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
              field(
                icon: Icons.comment_outlined,
                hint: "Коментар (звідки саме, куди саме...)",
                controller: commentController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: createTrip,
                  child: const Text(
                    "Створити поїздку",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
