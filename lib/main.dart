import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/main_tabs.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RouteXApp());
}

class RouteXApp extends StatelessWidget {
  const RouteXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // 🎨 Світлий сине-білий UI
        scaffoldBackgroundColor: const Color(0xFFE8F0FE),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFFD0DCFA),
          secondary: Color(0xFF1F2A44),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8F0FE),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2A44),
          ),
          iconTheme: IconThemeData(color: Color(0xFF1F2A44)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF1F2A44)),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            padding: WidgetStateProperty.all(
              EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFE8F0FE),
          selectedItemColor: Color(0xFF1F2A44),
          unselectedItemColor: Colors.black45,
        ),
      ),
      home: const MainTabs(),
    );
  }
}
