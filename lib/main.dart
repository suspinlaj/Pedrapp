import 'package:flutter/material.dart';
import 'package:pedrapp/features/portada/portada_pantalla.dart';

void main() {
  runApp(const PedrApp());
}

class PedrApp extends StatelessWidget {
  const PedrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PedrApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PortadaPantalla(),
    );
  }
}