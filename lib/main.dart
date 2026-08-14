import 'package:flutter/material.dart';
import 'package:guoguo/ui/home/home_screen.dart';

void main() {
  runApp(const GuoguoApp());
}

class GuoguoApp extends StatelessWidget {
  const GuoguoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guoguo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        fontFamily: '.SF Pro Text',
      ),
      home: const HomeScreen(),
    );
  }
}
