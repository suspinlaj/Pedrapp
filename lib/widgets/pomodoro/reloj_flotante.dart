import 'package:flutter/material.dart';
import 'package:pedrapp/controller/pomodoro_controller.dart';
import 'package:pedrapp/core/colores.dart';
import 'dart:async';

class RelojFlotante {
  static OverlayEntry? _overlay;
  // Posición inicial
  static Offset _posicion = const Offset(20, 100);

  static void mostrar(BuildContext context, PomodoroController controller) {
    if (_overlay != null) return; 

    _overlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: _posicion.dx,
          top: _posicion.dy,
          child: GestureDetector(
            // --- Permite arrastrar el reloj por la pantalla ---
            onPanUpdate: (details) {
              _posicion += details.delta;
              _overlay?.markNeedsBuild(); 
            },
            child: Material(
              color: Colors.transparent, 
              // Llamamos al widget que tiene la animación
              child: BurbujaRelojInteractiva(controller: controller),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  static void ocultar() {
    _overlay?.remove();
    _overlay = null;
  }
}

// --- WIDGET AISLADO PARA MANEJAR LA ANIMACIÓN DEL PLAY/PAUSA ---
class BurbujaRelojInteractiva extends StatefulWidget {
  final PomodoroController controller;
  
  const BurbujaRelojInteractiva({super.key, required this.controller});

  @override
  State<BurbujaRelojInteractiva> createState() => _BurbujaRelojInteractivaState();
}

class _BurbujaRelojInteractivaState extends State<BurbujaRelojInteractiva> {
  bool _mostrarIcono = false;
  IconData _iconoActual = Icons.pause;
  Timer? _animacionTimer;

  // Lógica al pulsar el círculo
  void _toggleTimer() {
    // 1. Pausa o reanuda el controlador
    widget.controller.startStopTimer();
    
    // 2. Muestra el icono transparente
    setState(() {
      _iconoActual = widget.controller.isRunning ? Icons.play_arrow : Icons.pause;
      _mostrarIcono = true;
    });

    // 3. Lo oculta automáticamente después de 1 segundo
    _animacionTimer?.cancel(); // Cancelamos si pulsa muy rápido
    _animacionTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _mostrarIcono = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animacionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final colorFondo = widget.controller.isFocusMode ? Colores.rojo : Colores.amarillo;
        final colorLetra = widget.controller.isFocusMode ? Colors.white : Colors.black87;

        return GestureDetector(
          onTap: _toggleTimer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- EL CÍRCULO PRINCIPAL ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorFondo,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colorFondo.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.controller.formatTime(),
                  style: TextStyle(
                    color: colorLetra,
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // Más grande para ocupar todo
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              // --- EL ICONO ANIMADO (FADE IN / FADE OUT) ---
              // Ignora los toques para que no interfiera con el arrastre
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _mostrarIcono ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300), // Tarda 0.3s en aparecer/desaparecer
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), // Fondo oscuro semitransparente
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconoActual,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}