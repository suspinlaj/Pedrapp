import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:pedrapp/modelos/cancion_pomodoro.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart'; 
import 'package:pedrapp/data/canciones_data.dart';   
import 'package:pedrapp/servicios/pomodoro_service.dart';
import 'package:pedrapp/servicios/notificaciones_service.dart';

class PomodoroController extends ChangeNotifier with WidgetsBindingObserver {
  
  // Tiempos por defecto al abrir la app
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;

  // UN controlador en toda la app para que el reloj no se reinicie al salir de la pantalla
  static final PomodoroController _instance = PomodoroController._internal();
  factory PomodoroController() => _instance;

  // --- VARIABLES DEL TEMPORIZADOR ---
  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  
  Timer? _timer; // El reloj que cuenta hacia atrás
  Timer? _latidoEnPausaTimer; // pausas del boton flotante
  
  bool _isRunning = false; // saber si está corriendo el tiempo
  bool _isFocusMode = true; // saber si se está estudiando o descansando

  // --- VARIABLES DEL HISTORIAL ---
  int minutosHoy = 0;
  int minutosTotales = 0;

  // --- REPRODUCTORES MULTIMEDIA ---
  VideoPlayerController? estudioController;
  VideoPlayerController? descansoController;
  final AudioPlayer _musicPlayer = AudioPlayer(); // Reproductor de la música de fondo
  CancionPomodoro? _cancionSeleccionada;
  String? _rutaAudioCargada;

  // --- VARIABLES DE SISTEMA Y BURBUJA ---
  bool _isInitialized = false; // Evitar que se inicialice dos veces
  final ReceivePort _receivePort = ReceivePort(); //  escucha a la burbuja

  // --- CORTAFUEGOS UNIVERSAL ---
  // Evalúa si el dispositivo soporta burbujas nativas (Solo Android)
  bool get _soportaBurbujaFlotante {
    if (kIsWeb) return false; // Si es web o PC, prohibido
    return Platform.isAndroid; // Si no es web, solo permitir Android
  }

  // --- GETTERS --- (Formas de leer las variables desde la pantalla)
  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  bool get videoEstudioInicializado => estudioController?.value.isInitialized ?? false;
  bool get videoDescansoInicializado => descansoController?.value.isInitialized ?? false;
  CancionPomodoro? get cancionSeleccionada => _cancionSeleccionada;

  // Constructor interno privado
  PomodoroController._internal() {
    _secondsLeft = _defaultFocusMinutes * 60;
  }

  // --- INICIALIZACIÓN GLOBAL ---
  // Se llama cuando se abre la pantalla por primera vez
  void inicializar(BuildContext context) {
    if (_isInitialized) return; 

    //  para escuchar si cierran la app
    WidgetsBinding.instance.addObserver(this);

    // --- CONEXIÓN CON LA BURBUJA (Solo Android) ---
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'pomodoro_port');
      
      // saber si se pulsa Play/Pausa en la burbuja flotante
      _receivePort.listen((message) {
        if (message == "TOGGLE") {
          startStopTimer(); 
        }
      });

      FlutterOverlayWindow.overlayListener.listen((event) {
        if (event == "TOGGLE") {
          startStopTimer(); 
        }
      });
    }

    // Arrancar notificaciones, vídeos, música e historial
    NotificacionesService.inicializar();
    _initializeVideos();
    _cargarHistorial();
    _cargarAjustesMusica(); 
    _configureAudioSession(); 

    _isInitialized = true;
  }

  // --- CIERRE DE APP ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // quitar burbuja si se cierra la app
    if (state == AppLifecycleState.detached) {
      _matarRelojFlotante();
    }
  }

  // Limpieza de memoria 
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _latidoEnPausaTimer?.cancel();
    
    // Cerrar puerto de comunicación
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      _receivePort.close();
    }
    super.dispose();
  }

  // --- SINCRONIZACIÓN CON BURBUJA FLOTANTE ---
  // Envía el tiempo actual y el estado a la burbuja invisible en memoria
  void _sincronizarRelojFlotante() async {
    if (!_soportaBurbujaFlotante) return; 

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      String paquete = "SYNC|${formatTime()}|$_isFocusMode|$_isRunning";
      overlayPort.send(paquete);
    }
  }

  // Obliga a la burbuja a cerrarse
  void _matarRelojFlotante() {
    if (!_soportaBurbujaFlotante) return; 

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      overlayPort.send("KILL");
    }
    FlutterOverlayWindow.closeOverlay();
  }

  // --- MÚSICA ---
  // Recupera la última canción que se eligio 
  Future<void> _cargarAjustesMusica() async {
    final prefs = await SharedPreferences.getInstance();
    final String cancionGuardadaId = prefs.getString('pomodoro_musica_id') ?? 'ninguno';
    
    _cancionSeleccionada = CancionesData.listaDeCanciones.firstWhere(
      (c) => c.id == cancionGuardadaId,
      orElse: () => CancionesData.listaDeCanciones.first, 
    );
    notifyListeners(); // Actualiza la pantalla
  }

  // Configura el audio 
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Si entra una llamada, música se pausa
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_musicPlayer.playing) {
          _musicPlayer.pause();
        }
      }
    });
  }

  // Reproduce o detiene la música según si estamos estudiando o descansando
  Future<void> _gestionarMusicaDeFondo() async {
    // parar la música si se está descansando
    if (_cancionSeleccionada == null || 
        _cancionSeleccionada!.id == 'ninguno' || 
        !_isFocusMode || 
        !_isRunning) {
      if (_musicPlayer.playing) {
        await _musicPlayer.stop();
      }
      return;
    }

    // Reproducir
    try {
      if (_rutaAudioCargada != _cancionSeleccionada!.assetPath) {
        await _musicPlayer.setAsset(_cancionSeleccionada!.assetPath);
        await _musicPlayer.setLoopMode(LoopMode.one); // Bucle infinito
        await _musicPlayer.setVolume(0.5); 
        _rutaAudioCargada = _cancionSeleccionada!.assetPath;
      }
      
      if (!_musicPlayer.playing) {
        final session = await AudioSession.instance;
        if (await session.setActive(true)) {
          _musicPlayer.play();
        }
      }
    } catch (e) {
      debugPrint("Error reproduciendo música: $e");
    }
  }

  // Guarda la canción elegida en la memoria del movik
  Future<void> seleccionarCancion(CancionPomodoro cancion) async {
    _cancionSeleccionada = cancion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_musica_id', cancion.id);
    if (_isFocusMode && _isRunning) _gestionarMusicaDeFondo();
    notifyListeners();
  }

  // --- VÍDEOS DIBUJO ---
  void _actualizarEstadoVideos() {
    final bool mostrarEstudio = _isFocusMode && _isRunning;
    if (mostrarEstudio) {
      descansoController?.pause();
      estudioController?.play();
    } else {
      estudioController?.pause();
      descansoController?.play();
    }
    notifyListeners();
  }

  // ---  HISTORIAL ---
  Future<void> _cargarHistorial() async {
    final datos = await PomodoroService.cargarHistorial();
    minutosTotales = datos['total'] ?? 0;
    minutosHoy = datos['hoy'] ?? 0;
    notifyListeners();
  }

  // sumar tiempo al historial 
  Future<void> _sumarTiempoAlHistorial(int minutos) async {
    minutosTotales += minutos;
    minutosHoy += minutos;
    notifyListeners();
    PomodoroService.sumarTiempoAlHistorial(minutos);
  }

  // Cargar archivos mp4
  void _initializeVideos() {
    estudioController = VideoPlayerController.asset('assets/images/pomodoro_estudio.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
      ..initialize().then((_) {
        estudioController?.setLooping(true);
        estudioController?.setVolume(0.0); // Mudos siempre
        _actualizarEstadoVideos();
        notifyListeners();
      });

    descansoController = VideoPlayerController.asset('assets/images/pomodoro_descanso.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
      ..initialize().then((_) {
        descansoController?.setLooping(true);
        descansoController?.setVolume(0.0);
        _actualizarEstadoVideos();
        notifyListeners();
      });
  }

  // --- TEMPORIZADOR ---
  // Botón Iniciar/Pausar
  void startStopTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  // Lógica principal de contar hacia atrás
  void _startTimer() {
    _isRunning = true;
    _latidoEnPausaTimer?.cancel(); 
    
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo();
    _sincronizarRelojFlotante(); 

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--; // Restar 1 segundo
        _showTimerNotification(); // Actualizar notificación del móvil
      } else {
        // --- CUANDO EL TIEMPO LLEGA A CERO ---
        timer.cancel();
        if (_isFocusMode) _sumarTiempoAlHistorial(_focusMinutes); // Si se está estudiando, sumar al historial
        _isFocusMode = !_isFocusMode; // Cambiar de modo (Estudio <-> Descanso)
        _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60; // Resetear el tiempo al nuevo modo
        _isRunning = false;
        _actualizarEstadoVideos();
        _gestionarMusicaDeFondo(); 
        _showCompletionNotification(); // Avisar de que acabó
      }
      
      _sincronizarRelojFlotante(); // Actualizar la burbuja
      notifyListeners(); // Actualizar la pantalla de la app
    });
  }

  // Pausar el reloj
  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo(); 
    NotificacionesService.cancelar();
    _sincronizarRelojFlotante(); 
    notifyListeners();

    // Burbuja flotante
    if (_soportaBurbujaFlotante) {
      _latidoEnPausaTimer?.cancel();
      _latidoEnPausaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sincronizarRelojFlotante();
      });
    }
  }

  // Botón de Reiniciar
  void resetTimer() {
    _stopTimer();
    _latidoEnPausaTimer?.cancel();
    _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
    _matarRelojFlotante(); // Destruir  burbuja
    notifyListeners();
  }

  // Cambiar el tiempo en los selectores de abajo
  void updateDuration({required bool isFocus, required int minutes}) {
    //  entre 1 y 180 minutos
    if (isFocus) {
      _focusMinutes = minutes.clamp(1, 180);
    } else {
      _breakMinutes = minutes.clamp(1, 180);
    }

    // Actualizar el reloj si no está corriendo y coincide con el modo actual
    if (_isFocusMode && isFocus) {
      _secondsLeft = _focusMinutes * 60;
    } else if (!_isFocusMode && !isFocus) {
      _secondsLeft = _breakMinutes * 60;
    }
    notifyListeners();
  }

  // Transformar los segundos brutos a formato 25:00
  String formatTime() {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- NOTIFICACIONES ---
  void _showTimerNotification() {
    final title = _isFocusMode ? 'Pomodoro: Estudio' : 'Pomodoro: Descanso';
    final body = 'Tiempo restante: ${formatTime()}';
    NotificacionesService.mostrarEnProgreso(title, body);
  }

  void _showCompletionNotification() {
    final title = _isFocusMode ? '¡A estudiar vago!' : 'Hora de tu esperado descansito awa';
    final body = _isFocusMode ? '¡Deja los juegos!, vuelta a estudiar jaja' : '¡Tiempo de hablar a la besto novia!';
    NotificacionesService.mostrarCompletado(title, body);
  }
}