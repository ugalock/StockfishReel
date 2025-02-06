import 'package:flutter/material.dart';
import 'views/landing/landing_screen.dart';

class StockfishReelApp extends StatelessWidget {
  const StockfishReelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockfishReel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
} 