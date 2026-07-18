import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';

// --- NUEVO: Imports para detectar si estamos en Web o Android ---
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
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;

  static final PomodoroController _instance = PomodoroController._internal();
  factory PomodoroController() => _instance;

  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  
  Timer? _timer;
  Timer? _latidoEnPausaTimer;
  
  bool _isRunning = false;
  bool _isFocusMode = true;

  int minutosHoy = 0;
  int minutosTotales = 0;

  VideoPlayerController? estudioController;
  VideoPlayerController? descansoController;
  
  final AudioPlayer _musicPlayer = AudioPlayer(); 
  CancionPomodoro? _cancionSeleccionada;
  String? _rutaAudioCargada;

  bool _isInitialized = false; 
  final ReceivePort _receivePort = ReceivePort();

  // --- MAGIA: Comprobador universal para evitar crasheos en Web/PC/iOS ---
  bool get _soportaBurbujaFlotante {
    if (kIsWeb) return false; // Si es web, devolvemos false al instante
    return Platform.isAndroid; // Si no es web, comprobamos si es Android
  }

  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  bool get videoEstudioInicializado => estudioController?.value.isInitialized ?? false;
  bool get videoDescansoInicializado => descansoController?.value.isInitialized ?? false;
  CancionPomodoro? get cancionSeleccionada => _cancionSeleccionada;

  PomodoroController._internal() {
    _secondsLeft = _defaultFocusMinutes * 60;
  }

  void inicializar(BuildContext context) {
    if (_isInitialized) return; 

    WidgetsBinding.instance.addObserver(this);

    // SOLO abrimos los puertos de memoria si estamos en Android
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'pomodoro_port');
      
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

    NotificacionesService.inicializar();
    _initializeVideos();
    _cargarHistorial();
    _cargarAjustesMusica(); 
    _configureAudioSession(); 

    _isInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _matarRelojFlotante();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _latidoEnPausaTimer?.cancel();
    
    // Solo cerramos puertos si estamos en Android
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      _receivePort.close();
    }
    super.dispose();
  }

  void _sincronizarRelojFlotante() async {
    if (!_soportaBurbujaFlotante) return; // Cortafuegos para Web/PC

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      String paquete = "SYNC|${formatTime()}|$_isFocusMode|$_isRunning";
      overlayPort.send(paquete);
    }
  }

  void _matarRelojFlotante() {
    if (!_soportaBurbujaFlotante) return; // Cortafuegos para Web/PC

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      overlayPort.send("KILL");
    }
    FlutterOverlayWindow.closeOverlay();
  }

  Future<void> _cargarAjustesMusica() async {
    final prefs = await SharedPreferences.getInstance();
    final String cancionGuardadaId = prefs.getString('pomodoro_musica_id') ?? 'ninguno';
    
    _cancionSeleccionada = CancionesData.listaDeCanciones.firstWhere(
      (c) => c.id == cancionGuardadaId,
      orElse: () => CancionesData.listaDeCanciones.first, 
    );
    notifyListeners();
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_musicPlayer.playing) {
          _musicPlayer.pause();
        }
      }
    });
  }

  Future<void> _gestionarMusicaDeFondo() async {
    if (_cancionSeleccionada == null || 
        _cancionSeleccionada!.id == 'ninguno' || 
        !_isFocusMode || 
        !_isRunning) {
      if (_musicPlayer.playing) {
        await _musicPlayer.stop();
      }
      return;
    }

    try {
      if (_rutaAudioCargada != _cancionSeleccionada!.assetPath) {
        await _musicPlayer.setAsset(_cancionSeleccionada!.assetPath);
        await _musicPlayer.setLoopMode(LoopMode.one); 
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

  Future<void> seleccionarCancion(CancionPomodoro cancion) async {
    _cancionSeleccionada = cancion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_musica_id', cancion.id);
    if (_isFocusMode && _isRunning) _gestionarMusicaDeFondo();
    notifyListeners();
  }

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

  Future<void> _cargarHistorial() async {
    final datos = await PomodoroService.cargarHistorial();
    minutosTotales = datos['total'] ?? 0;
    minutosHoy = datos['hoy'] ?? 0;
    notifyListeners();
  }

  Future<void> _sumarTiempoAlHistorial(int minutos) async {
    minutosTotales += minutos;
    minutosHoy += minutos;
    notifyListeners();
    PomodoroService.sumarTiempoAlHistorial(minutos);
  }

  void _initializeVideos() {
    estudioController = VideoPlayerController.asset('assets/images/pomodoro_estudio.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
      ..initialize().then((_) {
        estudioController?.setLooping(true);
        estudioController?.setVolume(0.0);
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

  void startStopTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _isRunning = true;
    _latidoEnPausaTimer?.cancel(); 
    
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo();
    _sincronizarRelojFlotante(); 

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        _showTimerNotification();
      } else {
        timer.cancel();
        if (_isFocusMode) _sumarTiempoAlHistorial(_focusMinutes);
        _isFocusMode = !_isFocusMode;
        _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
        _isRunning = false;
        _actualizarEstadoVideos();
        _gestionarMusicaDeFondo(); 
        _showCompletionNotification();
      }
      
      _sincronizarRelojFlotante(); 
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo(); 
    NotificacionesService.cancelar();
    _sincronizarRelojFlotante(); 
    notifyListeners();

    if (_soportaBurbujaFlotante) {
      _latidoEnPausaTimer?.cancel();
      _latidoEnPausaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sincronizarRelojFlotante();
      });
    }
  }

  void resetTimer() {
    _stopTimer();
    _latidoEnPausaTimer?.cancel();
    _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
    _matarRelojFlotante();
    notifyListeners();
  }

  void updateDuration({required bool isFocus, required int minutes}) {
    if (isFocus) {
      _focusMinutes = minutes.clamp(1, 180);
    } else {
      _breakMinutes = minutes.clamp(1, 180);
    }

    if (_isFocusMode && isFocus) {
      _secondsLeft = _focusMinutes * 60;
    } else if (!_isFocusMode && !isFocus) {
      _secondsLeft = _breakMinutes * 60;
    }
    notifyListeners();
  }

  String formatTime() {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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