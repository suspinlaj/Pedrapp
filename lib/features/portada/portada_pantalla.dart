import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/core/frases.dart';
import 'package:pedrapp/features/menu/menu_pantalla.dart';
import 'package:pedrapp/widgets/dialog_recuperar_datos.dart'; 

class PortadaPantalla extends StatelessWidget {
  const PortadaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    // evitar redibujos innecesarios
    final altoPantalla = MediaQuery.sizeOf(context).height;
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    // carcular la frase una sola vez al cargar la pantalla 
    final fraseDelDia = Frases.obtenerFraseDelDia();

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
                _BomberoAnimado(altoPantalla: altoPantalla),

                const Spacer(flex: 1), 

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0), 
                  // --- FRASE DEL DÍA ---
                  child: Text(
                    '"$fraseDelDia"',
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

// GIF BOMBERO
class _BomberoAnimado extends StatefulWidget {
  final double altoPantalla;
  
  const _BomberoAnimado({required this.altoPantalla});

  @override
  State<_BomberoAnimado> createState() => _BomberoAnimadoState();
}

class _BomberoAnimadoState extends State<_BomberoAnimado> {
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
    return Image.asset(
      _mostrarPrimeraImagen 
          ? 'assets/images/bombero1.png' 
          : 'assets/images/bombero2.png', 
      height: widget.altoPantalla * 0.35, 
    );
  }
}