import 'package:flutter/material.dart';
import 'package:pedrapp/features/portada/portada_pantalla.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Asegurarse de que Flutter está listo antes de arrancar nada
  WidgetsFlutterBinding.ensureInitialized();
  
  // Encender Firebase con archivo de configuración generado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Arrancar app
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