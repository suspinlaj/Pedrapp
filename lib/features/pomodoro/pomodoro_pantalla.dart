import 'package:flutter/material.dart';
import 'package:pedrapp/controller/pomodoro_controller.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/widgets/pomodoro/selector_musica.dart';
import 'package:video_player/video_player.dart';
import 'package:pedrapp/widgets/pomodoro/selector_tiempo.dart';
import 'package:pedrapp/widgets/pomodoro/dialog_historial.dart';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PomodoroPantalla extends StatefulWidget {
  const PomodoroPantalla({super.key});

  @override
  State<PomodoroPantalla> createState() => _PomodoroPantallaState();
}

class _PomodoroPantallaState extends State<PomodoroPantalla> {
  final PomodoroController _controller = PomodoroController();

  @override
  void initState() {
    super.initState();
    _controller.inicializar(context);
  }

  Future<void> _iniciarPomodoroGlobal() async {
    if (!_controller.isRunning) {
      bool? isGranted = await FlutterOverlayWindow.isPermissionGranted();
      
      if (isGranted != true) {
        await FlutterOverlayWindow.requestPermission();
        return; 
      }
      
      if (await FlutterOverlayWindow.isActive() == false) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          // Dejamos los textos casi vacíos o minimalistas
          overlayTitle: "Pedrapp", 
          overlayContent: "⌛", 
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.center,
          // MAGIA: Le pedimos a Android que la oculte lo máximo posible
          visibility: NotificationVisibility.visibilitySecret, 
          positionGravity: PositionGravity.auto,
          width: 300, 
          height: 300,
        );
      }
    }

    _controller.startStopTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double videoSize = size.width > 400 ? 280.0 : size.width * 0.73;
    final double paddingVertical = size.height * 0.04;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final colorTema = _controller.isFocusMode ? Colores.rojo : Colores.amarillo;
        final bool mostrarEstudio = _controller.isFocusMode && _controller.isRunning;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                'Pomodoro',
                style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
              ),
            ),
            backgroundColor: Colores.rojo,
            shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white, size: 30),
                tooltip: 'Ver historial',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DialogHistorial(
                      minutosHoy: _controller.minutosHoy,
                      minutosTotales: _controller.minutosTotales,
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
            ],
          ),
          body: Stack(
            children: [
              // --- CAPA 1 (FONDO): EL REPRODUCTOR DE VÍDEO ---
              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  width: videoSize,
                  height: videoSize,
                  child: mostrarEstudio
                      ? (_controller.videoEstudioInicializado
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.estudioController!.value.size.width,
                                height: _controller.estudioController!.value.size.height,
                                child: VideoPlayer(_controller.estudioController!),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colores.rojo)))
                      : (_controller.videoDescansoInicializado
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.descansoController!.value.size.width,
                                height: _controller.descansoController!.value.size.height,
                                child: VideoPlayer(_controller.descansoController!),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colores.amarillo))),
                ),
              ),

              // --- CAPA 2 (FRENTE): TODO EL CONTENIDO ---
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 40, bottom: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _controller.isFocusMode ? '¡a estudiar vago!' : 'tiempo de haBLar a La Besto novia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Titulo',
                              letterSpacing: 1.5,
                              color: colorTema,
                            ),
                          ),
                        ),
                        SizedBox(height: paddingVertical),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorTema, width: 4),
                          ),
                          child: Text(
                            _controller.formatTime(), 
                            style: TextStyle(
                              fontSize: size.width > 350 ? 80 : 65,
                              fontWeight: FontWeight.bold,
                              color: colorTema,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        SizedBox(height: paddingVertical),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SelectorTiempo(
                              label: 'Estudio',
                              value: _controller.focusMinutes,
                              colorTema: Colores.rojo,
                              onChanged: (value) => _controller.updateDuration(isFocus: true, minutes: value),
                            ),
                            SelectorTiempo(
                              label: 'Descanso',
                              value: _controller.breakMinutes,
                              colorTema: Colores.amarillo,
                              onChanged: (value) => _controller.updateDuration(isFocus: false, minutes: value),
                            ),
                          ],
                        ),
                        SizedBox(height: paddingVertical),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            // --- BOTÓN MÚSICA ---
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent, 
                                  builder: (context) => SelectorMusicaSheet(
                                    controller: _controller, 
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colores.gris, width: 3),
                                ),
                                child: ListenableBuilder(
                                  listenable: _controller,
                                  builder: (context, _) {
                                    final hayMusica = _controller.cancionSeleccionada != null && 
                                                      _controller.cancionSeleccionada!.id != 'ninguno';
                                    return Icon(
                                      hayMusica ? Icons.headset_mic : Icons.music_note, 
                                      color: hayMusica ? Colores.rojo : Colores.gris, 
                                      size: 30
                                    );
                                  }
                                ),
                              ),
                            ),

                            // --- BOTÓN INICIAR / PAUSAR ---
                            GestureDetector(
                              onTap: _iniciarPomodoroGlobal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                decoration: BoxDecoration(
                                  color: colorTema,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colores.gris, width: 3),
                                ),
                                child: Text(
                                  _controller.isRunning ? 'Pausar' : 'Iniciar',
                                  style: TextStyle(
                                      color: _controller.isFocusMode ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                            ),

                            // --- BOTÓN REINICIAR ---
                            GestureDetector(
                              onTap: () {
                                _controller.resetTimer(); 
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colores.gris, width: 3),
                                ),
                                child: const Icon(Icons.refresh, color: Colores.gris, size: 30),
                              ),
                            ),
                          ],
                        ),
                      ],
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