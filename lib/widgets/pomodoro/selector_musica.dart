import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; 
import 'package:pedrapp/controller/pomodoro_controller.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/cancion_pomodoro.dart';
import 'package:pedrapp/data/canciones_data.dart';   

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
  final AudioPlayer _previewPlayer = AudioPlayer();
  
  // Almacenar identificador de la canción actualmente en prueba
  String? _idCancionSonandoPreview;

  @override
  void dispose() {
    // Destruir reproductor temporal al cerrar la pestaña
    _previewPlayer.dispose();
    super.dispose();
  }

  // Alternar reproducción de prueba del archivo de audio
  Future<void> _togglePreview(CancionPomodoro cancion) async {
    // Ignorar acción si la opción es "Ninguno"
    if (cancion.id == 'ninguno') return;

    // Pausar audio si la canción seleccionada ya está sonando
    if (_idCancionSonandoPreview == cancion.id) {
      await _previewPlayer.pause();
      setState(() {
        _idCancionSonandoPreview = null;
      });
    } 
    // Cargar y reproducir nueva canción seleccionada
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
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colores.gris.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              
              // TITULO
              const Text(
                'Musica de Fondo',
                style: TextStyle(
                  color: Colores.rojo,
                  fontFamily: 'Titulo',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              
              // lista desplazable de opciones 
              Expanded(
                child: ListView.builder(
                  // Contar total de canciones disponibles en la base de datos
                  itemCount: CancionesData.listaDeCanciones.length,
                  itemBuilder: (context, index) {
                    // Obtener datos de la canción en la posición actual
                    final cancion = CancionesData.listaDeCanciones[index];
                    
                    // Verificar si la canción es la configurada 
                    final bool esSeleccionadaOficial = widget.controller.cancionSeleccionada?.id == cancion.id ||
                        (widget.controller.cancionSeleccionada == null && cancion.id == 'ninguno');
                    
                    // Verificar si la canción se está reproduciendo en previsualización
                    final bool esPreviewActual = _idCancionSonandoPreview == cancion.id;

                    return GestureDetector(
                      onTap: () {
                        // Establecer canción como oficial en el controlador
                        widget.controller.seleccionarCancion(cancion);
                        
                        Navigator.pop(context); 
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        // COLORES
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
                            // ICONOS
                            Icon(cancion.icono, color: esSeleccionadaOficial ? Colores.rojo : Colores.rojo, size: 28),
                            const SizedBox(width: 15),
                            
                            // TITULO
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

                            // ICONO DE PLAY/PAUSE PARA PREVISUALIZACIÓN
                            if (cancion.id != 'ninguno')
                              IconButton(
                                icon: Icon(
                                  esPreviewActual ? Icons.pause_circle_filled : Icons.play_circle_outline,
                                  color: esSeleccionadaOficial ? Colores.rojo : Colores.rojo,
                                  size: 32,
                                ),
                                onPressed: () => _togglePreview(cancion),
                              ),

                            // ICONO DE SELECCIÓN
                            if (esSeleccionadaOficial)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colores.rojo, size: 28),
                              ),
                              
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