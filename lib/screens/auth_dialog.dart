import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text("Авторизація"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Пароль"),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("Закрити"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  setState(() => isLoading = true);
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    try {
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Помилка: $e")),
                      );
                    }
                  }
                  setState(() => isLoading = false);
                },
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Увійти / Зареєструватися"),
        ),
      ],
    );
  }
}
