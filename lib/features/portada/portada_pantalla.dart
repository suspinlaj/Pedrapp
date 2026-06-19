import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/core/frases.dart';
import 'package:pedrapp/features/menu/menu_pantalla.dart';
import 'package:pedrapp/widgets/dialogs/dialog_recuperar_datos.dart'; 

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
    final altoPantalla = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: const AssetImage('assets/images/fondo_portada.png'),
            fit: isLandscape ? BoxFit.contain : BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                
                const Spacer(flex: 7), 
                
                RichText(
                  text: const TextSpan(
                    // --- TITULO ---
                    style: TextStyle(
                      fontFamily: 'Titulo', 
                      fontSize: 80,
                    ),
                    children: [
                      TextSpan(text: 'Pedr', style: TextStyle(color: Colores.gris)),
                      TextSpan(text: 'app', style: TextStyle(color: Colores.rojo)),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1), 

                // --- IMAGEN ANIMADA ---
                Image.asset(
                  _mostrarPrimeraImagen 
                      ? 'assets/images/bombero1.png' 
                      : 'assets/images/bombero2.png', 
                  height: altoPantalla * 0.35, 
                ),

                const Spacer(flex: 1), 

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

                const Spacer(flex: 2), 

                // --- BOTÓN ENTRAR ---
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MenuPantalla()),
                    );                    
                  },
                  style: TextButton.styleFrom(
                    splashFactory: NoSplash.splashFactory, 
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontFamily: 'Titulo', 
                      fontSize: 24,
                      color: Colores.rojo, 
                    ),
                  ),
                ),

                const Spacer(flex: 5), 

                // --- COPIA DE SEGURIDAD  ---
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DialogRecuperarDatos(),
                    );
                  },
                  child: const Text(
                    'Copia de seguridad',
                    style: TextStyle(
                      color: Colores.rojo,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}