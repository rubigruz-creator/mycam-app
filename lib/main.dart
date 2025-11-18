// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/save_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCam',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C40E2),
          brightness: Brightness.dark,
          primary: const Color(0xFF6C40E2),
          secondary: const Color(0xFFFF7B00),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F2D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F3D),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/save': (context) => const SaveScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}