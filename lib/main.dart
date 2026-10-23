import 'package:flutter/material.dart';
import 'screens/game_screens.dart';

void main (){
  runApp(const BouncerApp());
}

class BouncerApp extends StatelessWidget {
  const BouncerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}