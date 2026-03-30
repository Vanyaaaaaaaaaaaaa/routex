import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  late TextEditingController nameController;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: user?.displayName ?? "");
    bioController = TextEditingController(text: user?.photoURL ?? "");
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    try {
      await user!.updateDisplayName(nameController.text.trim());
      await user!
          .updatePhotoURL(bioController.text.trim()); // зберігаємо "біо" тут

      await user!.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Збережено ✔")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Помилка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Редагування профілю",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ваше ім’я",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 12),
              _inputCard(
                controller: nameController,
                hint: "Введіть ім’я",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              const Text("Про себе",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 12),
              _inputCard(
                controller: bioController,
                hint: "Розкажіть про себе",
                icon: Icons.edit_note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saveProfile,
                  child: const Text(
                    "Зберегти зміни",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
    );
  }

  Widget _inputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
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
        maxLines: maxLines,
        controller: controller,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54, size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}
