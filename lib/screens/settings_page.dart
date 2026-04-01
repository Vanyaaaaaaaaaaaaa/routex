import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trip_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? selectedCity;
  bool notificationsEnabled = true;
  String selectedLanguage = "Українська";
  final List<String> cities = ["Київ", "Львів", "Одеса", "Харків", "Дніпро", "Івано-Франківськ", "Вінниця"];
  final passwordController = TextEditingController();

  Future<void> _saveSettings() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Налаштування збережено! ⚙️")),
    );
  }

  Future<void> _changePassword() async {
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароль має бути не менше 6 символів")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
      passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Пароль успішно змінено! 🛡️")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка при зміні пароля: $e")),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Видалити акаунт?"),
        content: const Text("Це неможливо буде скасувати. Всі ваші дані буде видалено."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Скасувати")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Видалити", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Спершу перезайдіть у застосунок для видалення: $e")),
          );
        }
      }
    }
  }

  Future<void> _seedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Оновити поїздки?"),
        content: const Text("Це видалить кілька старих поїздок та додасть нові цікаві маршрути."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Скасувати")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Оновити", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await TripService.seedData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Базу даних успішно оновлено! 🚀")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Помилка при оновленні: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Налаштування"),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Керування даними (НОВА СЕКЦІЯ) ---
              const Text("Керування даними",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _seedDatabase,
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: const Text("Скинути та додати нові поїздки", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: Colors.black12),
              const SizedBox(height: 12),
              const Text("Ваше місто",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),
              _dropdown(
                value: selectedCity,
                items: cities,
                hint: "Оберіть місто",
                onChanged: (val) => setState(() => selectedCity = val),
              ),

              const SizedBox(height: 32),

              // --- Сповіщення ---
              _switchTile(
                title: "Сповіщення",
                subtitle: "Отримувати новини про поїздки",
                value: notificationsEnabled,
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),

              const SizedBox(height: 24),

              // --- Мова ---
              const Text("Мова застосунку",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),
              _dropdown(
                value: selectedLanguage,
                items: ["Українська", "English"],
                hint: "Оберіть мову",
                onChanged: (val) => setState(() => selectedLanguage = val!),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text("Зберегти всі налаштування"),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(color: Colors.black12),
              const SizedBox(height: 32),

              // --- Зміна пароля ---
              const Text("Зміна пароля",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),
              _input(passwordController, Icons.lock_outline, "Новий пароль", obscure: true),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _changePassword,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Оновити пароль", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              ),
              
              const SizedBox(height: 60),

              // --- Небезпечна зона ---
              const Text("Небезпечна зона",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.redAccent)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _deleteAccount,
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text("Видалити мій акаунт", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "RouteX v1.0.1",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.blueGrey)),
          dropdownColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _switchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.black,
      ),
    );
  }

  Widget _input(TextEditingController c, IconData icon, String hint, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}
