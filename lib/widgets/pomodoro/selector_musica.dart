// lib/widgets/pomodoro/selector_musica_sheet.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Reproductor temporal de preview
import 'package:pedrapp/controller/pomodoro_controller.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/cancion_pomodoro.dart';

// --- NUEVOS IMPORTS: Cruciales para acceder al modelo y a los datos ---
import 'package:pedrapp/data/canciones_data.dart';   // import the data

// Cambiamos a StatefulWidget para poder manejar el reproductor temporal de preview
class SelectorMusicaSheet extends StatefulWidget {
  final PomodoroController controller;

  const SelectorMusicaSheet({
    super.key,
    required this.controller,
  });

  @override
  State<SelectorMusicaSheet> createState() => _SelectorMusicaSheetState();
}

class _SelectorMusicaSheetState extends State<SelectorMusicaSheet> {
  // Reproductor independiente solo para escuchar las pruebas
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _idCancionSonandoPreview;

  @override
  void dispose() {
    // Es crítico matar este reproductor al cerrar la pestaña para que se calle
    _previewPlayer.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE ESCUCHAR PRUEBA ---
  Future<void> _togglePreview(CancionPomodoro cancion) async {
    if (cancion.id == 'ninguno') return;

    // Si pulsas la misma que ya está sonando, la pausas
    if (_idCancionSonandoPreview == cancion.id) {
      await _previewPlayer.pause();
      setState(() {
        _idCancionSonandoPreview = null;
      });
    } 
    // Si pulsas una nueva, la cargas y la reproduces
    else {
      setState(() {
        _idCancionSonandoPreview = cancion.id;
      });
      try {
        await _previewPlayer.setAsset(cancion.assetPath);
        await _previewPlayer.setVolume(0.8);
        await _previewPlayer.setLoopMode(LoopMode.one);
        _previewPlayer.play();
      } catch (e) {
        debugPrint("Error al hacer preview: $e");
        setState(() {
          _idCancionSonandoPreview = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          // Limitamos el alto a máximo el 65% de la pantalla para evitar Overflow
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(color: Colores.rojo, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Barra de arrastre visual arriba
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colores.gris.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Musica de Fondo',
                style: TextStyle(
                  color: Colores.rojo,
                  fontFamily: 'Titulo',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              
              // --- EL LISTVIEW MÁGICO PARA EVITAR EL OVERFLOW ---
              Expanded(
                child: ListView.builder(
                  // --- CORRECCIÓN: Leemos directamente de la clase CancionesData ---
                  itemCount: CancionesData.listaDeCanciones.length,
                  itemBuilder: (context, index) {
                    // --- CORRECCIÓN: Leemos directamente de la clase CancionesData ---
                    final cancion = CancionesData.listaDeCanciones[index];
                    
                    // Comprobamos cuál es la oficial y cuál está sonando de prueba
                    final bool esSeleccionadaOficial = widget.controller.cancionSeleccionada?.id == cancion.id ||
                        (widget.controller.cancionSeleccionada == null && cancion.id == 'ninguno');
                    final bool esPreviewActual = _idCancionSonandoPreview == cancion.id;

                    return GestureDetector(
                      onTap: () {
                        // Al pulsar toda la caja, se SELECCIONA oficialmente y se guarda en la nube
                        widget.controller.seleccionarCancion(cancion);
                        Navigator.pop(context); // Cierra y mata el reproductor preview
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: esSeleccionadaOficial ? Colores.amarillo.withOpacity(0.1) : Colors.white,
                          border: Border.all(
                            color: esSeleccionadaOficial ? Colores.rojo : Colores.gris,
                            width: esSeleccionadaOficial ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(cancion.icono, color: esSeleccionadaOficial ? Colores.rojo : Colores.rojo, size: 28),
                            const SizedBox(width: 15),
                            
                            // Título de la canción
                            Expanded(
                              child: Text(
                                cancion.nombre,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: esSeleccionadaOficial ? FontWeight.bold : FontWeight.normal,
                                  color: esSeleccionadaOficial ? Colores.rojo : Colors.black87,
                                ),
                              ),
                            ),

                            // --- BOTÓN DE PLAY PARA ESCUCHARLA ANTES ---
                            if (cancion.id != 'ninguno')
                              IconButton(
                                icon: Icon(
                                  esPreviewActual ? Icons.pause_circle_filled : Icons.play_circle_outline,
                                  color: esSeleccionadaOficial ? Colores.rojo : Colores.rojo,
                                  size: 32,
                                ),
                                onPressed: () => _togglePreview(cancion),
                              ),

                            // Icono verde/rojo de confirmación de seleccionada
                            if (esSeleccionadaOficial)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colores.rojo, size: 28),
                              ),
                              
                            // Espaciado falso para alinear cuando la de 'ninguno' no tiene botón de Play
                            if (!esSeleccionadaOficial && cancion.id == 'ninguno')
                              const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}