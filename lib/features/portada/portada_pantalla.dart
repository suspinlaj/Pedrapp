import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/core/frases.dart';
import 'package:pedrapp/features/menu/menu_pantalla.dart'; 

class PortadaPantalla extends StatefulWidget {
  const PortadaPantalla({super.key});

  @override
  State<PortadaPantalla> createState() => _PortadaPantallaState();
}

class _PortadaPantallaState extends State<PortadaPantalla> {
  bool _mostrarPrimeraImagen = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        _mostrarPrimeraImagen = !_mostrarPrimeraImagen;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Saber las medidas exactas de la pantalla del móvil
    final altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: altoPantalla, // Asegurar que el fondo ocupa todo el alto
        decoration: const BoxDecoration(
          // --- IMAGEN FONDO ---
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_portada.png'), 
            fit: BoxFit.fill, 
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  
                  SizedBox(height: altoPantalla * 0.12), 
                  
                  RichText(
                    text: const TextSpan(
                      // --- TITULO ---
                      style: TextStyle(
                        fontFamily: 'Titulo', 
                        fontSize: 80,
                      ),
                      children: [
                        // 1º PARTE
                        TextSpan(
                          text: 'Pedr',
                          style: TextStyle(color: Colores.gris), 
                        ),
                        // 2º PARTE
                        TextSpan(
                          text: 'app',
                          style: TextStyle(color: Colores.rojo), 
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: altoPantalla * 0.02), 

                  // --- IMAGEN ANIMADA ---
                  Image.asset(
                    _mostrarPrimeraImagen 
                        ? 'assets/images/bombero1.png' 
                        : 'assets/images/bombero2.png', 
                    height: altoPantalla * 0.35, 
                  ),

                  SizedBox(height: altoPantalla * 0.04), 

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0), 
                    // --- FRASE DEL DÍA ---
                    child: Text(
                      '"${Frases.obtenerFraseDelDia()}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic, 
                        color: Colors.black, 
                      ),
                    ),
                  ),

                  SizedBox(height: altoPantalla * 0.08), 

                  // --- BOTÓN ENTRAR ---
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MenuPantalla()),
                          );                    },
                    style: TextButton.styleFrom(
                      splashFactory: NoSplash.splashFactory, 
                    ),
                    // --- TEXTO DEL BOTÓN ---
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontFamily: 'Titulo', 
                        fontSize: 24,
                        color: Colores.rojo, 
                      ),
                    ),
                  ),

                  SizedBox(height: altoPantalla * 0.05), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}