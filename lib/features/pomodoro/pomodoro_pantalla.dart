import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
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

  bool isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _controller.inicializar(context);
    _checkOverlayPermission();
  }

  /// Comprueba si el permiso de overlay ya está concedido al entrar
  Future<void> _checkOverlayPermission() async {
    if (_soportaBurbujaFlotante) {
      bool? isGranted = await FlutterOverlayWindow.isPermissionGranted();
      bool isActive = await FlutterOverlayWindow.isActive();
      setState(() {
        isOverlayActive = isGranted == true && isActive;
      });
    }
  }

  // --- Comprobador universal ---
  // para saber si el dispositivo soporta la burbuja flotante del pomodoro (solo Android)
  bool get _soportaBurbujaFlotante {
    if (kIsWeb) return false; // Web no lo soporta
    return Platform.isAndroid; // iOS tampoco, solo Android
  }

  // --- MÉTODOS DE LA BURBUJA ---
  Future<void> _mostrarBurbuja() async {
    if (!await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true, // Permitir moverla con el dedo
        overlayTitle: "Pedrapp",
        overlayContent: "⌛",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilitySecret,
        positionGravity: PositionGravity.none,
        width: 200,
        height: 200,
      );
    }
  }

  Future<void> _cerrarBurbuja() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  // --- BOTÓN PLAY/PAUSA ---
  Future<void> _iniciarPomodoroGlobal() async {
    // Si estamos en la Web, en iOS o en Escritorio, iniciamos el reloj y NO se abre la burbuja
    if (!_soportaBurbujaFlotante) {
      _controller.startStopTimer();
      return;
    }

    // EN ANDROID
    if (!_controller.isRunning) {
      // Si la preferencia está activa, mostramos la burbuja
      if (isOverlayActive) {
        await _mostrarBurbuja();
      }
    }

    // empezar a contar el tiempo
    _controller.startStopTimer();
  }

  @override
  Widget build(BuildContext context) {
    // Variables para hacer que la pantalla se adapte al tamaño del móvil o tablet
    final size = MediaQuery.of(context).size;
    // Escalar el tamaño del vídeo dependiendo del formato
    final double videoSize = size.width > 800
        ? 350.0 // Tamaño Web/Escritorio
        : size.width > 500
            ? 250.0 // Tamaño Tablets
            : size.width * 0.73; // Tamaño Móviles

    final double paddingVertical = size.height * 0.04;

    // Cada vez que el reloj resta un segundo, redibuja esta pantalla automáticamente.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // color según estudio o descanso
        final colorTema = _controller.isFocusMode ? Colores.rojo : Colores.amarillo;
        final bool mostrarEstudio = _controller.isFocusMode && _controller.isRunning;

        return Scaffold(
          backgroundColor: Colors.white,

          // --- BARRA SUPERIOR ---
          appBar: AppBar(
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context), // Botón para volver atrás
            ),
            title: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              // Titulo
              child: Text(
                'Pomodoro',
                style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
              ),
            ),
            backgroundColor: Colores.rojo,
            shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
            elevation: 0,
            actions: [
              // Muestra el switch únicamente si la plataforma soporta burbuja
              if (_soportaBurbujaFlotante)
                IconButton(
                  icon: Icon(
                    Icons.layers,
                    // Verde si está activo, blanco/opaco si está desactivado
                    color: isOverlayActive ? Colors.white : const Color.fromARGB(185, 234, 178, 182),
                    size: 28,
                  ),
                  tooltip: isOverlayActive ? 'Burbuja activada' : 'Burbuja desactivada',
                  onPressed: () async {
                    final bool nuevoEstado = !isOverlayActive;

                    if (nuevoEstado) {
                      // 1. Verificar si tenemos permiso otorgado por Android
                      bool? isGranted = await FlutterOverlayWindow.isPermissionGranted();

                      if (isGranted != true) {
                        // Si no hay permiso, redirigimos a los ajustes
                        await FlutterOverlayWindow.requestPermission();
                        // Re-comprobar si el usuario lo activó
                        isGranted = await FlutterOverlayWindow.isPermissionGranted();
                      }

                      if (isGranted == true) {
                        setState(() {
                          isOverlayActive = true;
                        });

                        // Si el tiempo ya está corriendo, mostramos la burbuja de inmediato
                        if (_controller.isRunning) {
                          await _mostrarBurbuja();
                        }
                      }
                    } else {
                      // Al desactivar, cerramos la burbuja si estaba activa
                      await _cerrarBurbuja();
                      setState(() {
                        isOverlayActive = false;
                      });
                    }
                  },
                ),
              // Botón estadísticas
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
              // --- DIBUJO VIDEO ---
              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  width: videoSize,
                  height: videoSize,
                  // Muestra un vídeo u otro dependiendo del modo
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

              // --- CONTENIDO INTERACTIVO ---
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 40, bottom: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // --- FRASE PRINCIPAL ---
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

                        // --- RELOJ GIGANTE ---
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

                        // --- SELECTORES DE MINUTOS (Botones + / -) ---
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            // ESTUDIO
                            SelectorTiempo(
                              label: 'Estudio',
                              value: _controller.focusMinutes,
                              colorTema: Colores.rojo,
                              onChanged: (value) => _controller.updateDuration(isFocus: true, minutes: value),
                            ),
                            // DESCANSO
                            SelectorTiempo(
                              label: 'Descanso',
                              value: _controller.breakMinutes,
                              colorTema: Colores.amarillo,
                              onChanged: (value) => _controller.updateDuration(isFocus: false, minutes: value),
                            ),
                          ],
                        ),
                        SizedBox(height: paddingVertical),

                        // --- BOTONES INFERIORES ---
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            // BOTÓN DE MÚSICA
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
                                      size: 30,
                                    );
                                  },
                                ),
                              ),
                            ),

                            // BOTÓN DE INICIAR / PAUSAR
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
                                    color: _controller.isFocusMode ? Colors.white : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),

                            // BOTÓN REINICIAR
                            GestureDetector(
                              onTap: () {
                                _controller.resetTimer();
                                if (_soportaBurbujaFlotante) {
                                  _cerrarBurbuja();
                                }
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