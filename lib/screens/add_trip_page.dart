import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../services/trip_service.dart';
import 'map_picker_page.dart';

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

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  gmaps.LatLng? pickedLocation;

  Future<void> pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null && result is gmaps.LatLng) {
      setState(() {
        pickedLocation = result;
      });
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: selectedDate ?? now,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        dateController.text = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
        final hour = time.hour.toString().padLeft(2, '0');
        final minute = time.minute.toString().padLeft(2, '0');
        timeController.text = "$hour:$minute";
      });
    }
  }

  Future<void> createTrip() async {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        seatsController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заповніть усі поля")),
      );
      return;
    }

    final finalDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (finalDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не можна створити поїздку в минулому 🕰️")),
      );
      return;
    }

    await TripService.addTrip(
      from: fromController.text.trim(),
      to: toController.text.trim(),
      dateTime: finalDateTime,
      seats: int.parse(seatsController.text),
      price: priceController.text.trim(),
      comment: commentController.text.trim(),
      lat: pickedLocation?.latitude,
      lng: pickedLocation?.longitude,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Поїздку створено ✔")),
      );
    }
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
            color: Colors.black.withValues(alpha: 0.04),
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
              const SizedBox(height: 8),
              if (pickedLocation != null) ...[
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: ll.LatLng(pickedLocation!.latitude, pickedLocation!.longitude),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: ll.LatLng(pickedLocation!.latitude, pickedLocation!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => setState(() => pickedLocation = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 20, color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              field(
                icon: Icons.map_outlined,
                hint: pickedLocation == null ? "Вказати місце збору на карті" : "Змінити місце збору",
                controller: TextEditingController(),
                readOnly: true,
                onTap: pickLocation,
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
