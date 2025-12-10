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

  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );

    if (date != null) {
      dateController.text = "${date.day}.${date.month}.${date.year}";
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      timeController.text = time.format(context);
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Нова поїздка",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1E28),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            field(
              icon: Icons.location_on,
              hint: "Звідки",
              controller: fromController,
            ),
            field(
              icon: Icons.flag,
              hint: "Куди",
              controller: toController,
            ),
            field(
              icon: Icons.calendar_today,
              hint: "Дата",
              controller: dateController,
              readOnly: true,
              onTap: pickDate,
            ),
            field(
              icon: Icons.access_time,
              hint: "Час",
              controller: timeController,
              readOnly: true,
              onTap: pickTime,
            ),
            field(
              icon: Icons.chair,
              hint: "Кількість місць",
              controller: seatsController,
            ),
            field(
              icon: Icons.attach_money,
              hint: "Ціна (грн)",
              controller: priceController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: createTrip,
                child: const Text(
                  "Створити поїздку",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
