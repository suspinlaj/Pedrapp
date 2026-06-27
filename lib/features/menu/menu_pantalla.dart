import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/features/mapa/mapa_pantalla.dart';
import 'package:pedrapp/features/marcas/marcas_pantalla.dart';
import 'package:pedrapp/features/pomodoro/pomodoro_pantalla.dart';

class MenuPantalla extends StatelessWidget {
  const MenuPantalla({super.key});

  @override
  Widget build(BuildContext context) {
final isLandscape =
    MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // CIMAGEN DE FONDO
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_portada.png',
              fit: isLandscape ? BoxFit.contain : BoxFit.fill,
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                  children: [
                    
                    // --- CABECERA: BOTÓN + TÍTULO ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context), // Vuelve a la pantalla anterior
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 6.0), 
                            child: Icon(
                              Icons.arrow_back, 
                              color: Colores.rojo, 
                              size: 45,           
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 15), 
                        
                        const Expanded(
                          // TITULO
                          child: Text(
                            'Funciones',
                            style: TextStyle(
                              fontFamily: 'Titulo', 
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colores.gris,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50), 

                    // --- MAPA DE LUGARES ---
                    _buildFlatButton(
                      context,
                      titulo: 'MAPA DE LUGARES',
                      icono: Icons.map,
                      colorFondo: Colores.rojo,
                      colorTexto: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapaPantalla()),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- POMODORO ---
                    _buildFlatButton(
                      context,
                      titulo: 'POMODORO',
                      icono: Icons.timer,
                      colorFondo: Colors.white, 
                      colorTexto: Colores.gris,
                      // TODO: pantalla pomodoro
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PomodoroPantalla()),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- TUS MARCAS ---
                    _buildFlatButton(
                      context,
                      titulo: 'TUS MARCAS',
                      icono: Icons.fitness_center,
                      colorFondo: Colores.rojo,
                      colorTexto: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MarcasPantalla()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DISEÑO BOTÓN PERSONALIZADO REUTILIZABLE
  Widget _buildFlatButton(
    BuildContext context, {
    required String titulo,      // El texto que mostrará
    required IconData icono,     // El icono de la izquierda
    required Color colorFondo,   // Color de la caja
    required Color colorTexto,   // Color de las letras y el icono
    required VoidCallback onTap, // La acción que hace al pulsarlo
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colores.gris, width: 3),
        ),
        child: Row(
          children: [
            Icon(icono, size: 30, color: colorTexto), 
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colorTexto,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MENSAJE TEMPORAL (EN CONSTRUCCIÓN)
  void _mostrarProximamente(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Si me tratas muy bien \nlo verás más pronto que tarde awa',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colores.rojo,
        behavior: SnackBarBehavior.floating, 
      ),
    );
  }
}