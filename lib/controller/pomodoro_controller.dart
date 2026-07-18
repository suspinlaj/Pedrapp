// lib/controllers/pomodoro_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/cancion_pomodoro.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- NUEVOS IMPORTS ---
import 'package:pedrapp/data/canciones_data.dart';   // Importa los datos

import 'package:pedrapp/servicios/pomodoro_service.dart';
import 'package:pedrapp/servicios/notificaciones_service.dart';

// Ya no definimos CancionPomodoro aquí, viene del import.

class PomodoroController extends ChangeNotifier {
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;

  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true;

  int minutosHoy = 0;
  int minutosTotales = 0;

  VideoPlayerController? estudioController;
  VideoPlayerController? descansoController;
  
  final AudioPlayer _musicPlayer = AudioPlayer(); 
  CancionPomodoro? _cancionSeleccionada;
  String? _rutaAudioCargada;

  // Ya no definimos la lista aquí.

  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  bool get videoEstudioInicializado => estudioController?.value.isInitialized ?? false;
  bool get videoDescansoInicializado => descansoController?.value.isInitialized ?? false;
  CancionPomodoro? get cancionSeleccionada => _cancionSeleccionada;

  PomodoroController() {
    _secondsLeft = _defaultFocusMinutes * 60;
  }

  void inicializar(BuildContext context) {
    NotificacionesService.inicializar();
    _initializeVideos();
    _cargarHistorial();
    _cargarAjustesMusica(); 
    _configureAudioSession(); 
  }

  @override
  void dispose() {
    _timer?.cancel();
    estudioController?.dispose();
    descansoController?.dispose();
    _musicPlayer.dispose(); 
    super.dispose();
  }

  Future<void> _cargarAjustesMusica() async {
    final prefs = await SharedPreferences.getInstance();
    final String cancionGuardadaId = prefs.getString('pomodoro_musica_id') ?? 'ninguno';
    
    // Usamos CancionesData.listaDeCanciones para buscar
    _cancionSeleccionada = CancionesData.listaDeCanciones.firstWhere(
      (c) => c.id == cancionGuardadaId,
      // Si por alguna razón no se encuentra la ID (ej. cambiamos el nombre en los datos),
      // seleccionamos la primera por defecto.
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
    // Verificamos contra la ID 'ninguno' que ahora está en CancionesData
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
        // Esto garantiza el bucle
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

    if (_isFocusMode && _isRunning) {
      _gestionarMusicaDeFondo();
    }
    notifyListeners();
  }

  // ... El resto de métodos (_actualizarEstadoVideos, _cargarHistorial, etc.) 
  // permanecen igual ...

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
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo(); 

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
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo(); 
    NotificacionesService.cancelar();
    notifyListeners();
  }

  void resetTimer() {
    _stopTimer();
    _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
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