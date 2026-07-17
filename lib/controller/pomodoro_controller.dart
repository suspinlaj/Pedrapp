import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:pedrapp/servicios/pomodoro_service.dart';
import 'package:pedrapp/servicios/notificaciones_service.dart';

class PomodoroController extends ChangeNotifier {
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;

  // --- ESTADO DE LA APP (Privado) ---
  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true;

  // --- VARIABLES DEL HISTORIAL ---
  int minutosHoy = 0;
  int minutosTotales = 0;

  // --- CONTROLADORES DE VÍDEO ---
  VideoPlayerController? estudioController;
  VideoPlayerController? descansoController;

  // --- GETTERS (Para leer el estado desde la UI) ---
  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  bool get videoEstudioInicializado => estudioController?.value.isInitialized ?? false;
  bool get videoDescansoInicializado => descansoController?.value.isInitialized ?? false;

  PomodoroController() {
    _secondsLeft = _defaultFocusMinutes * 60;
  }

  // --- INICIALIZACIÓN ---
  void inicializar(BuildContext context) {
    NotificacionesService.inicializar();
    _initializeVideos();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _timer?.cancel();
    estudioController?.dispose();
    descansoController?.dispose();
    super.dispose();
  }

  // --- LÓGICA PRIVADA ---

  void _actualizarEstadoVideos() {
    final bool mostrarEstudio = _isFocusMode && _isRunning;
    if (mostrarEstudio) {
      descansoController?.pause();
      estudioController?.play();
    } else {
      estudioController?.pause();
      descansoController?.play();
    }
    notifyListeners(); // Avisar a la UI de que cambian los vídeos
  }

  Future<void> _cargarHistorial() async {
    final datos = await PomodoroService.cargarHistorial();
    minutosTotales = datos['total'] ?? 0;
    minutosHoy = datos['hoy'] ?? 0;
    notifyListeners(); // Avisar a la UI
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

  // --- FUNCIONES PÚBLICAS (Invocadas por la UI) ---

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
        _showCompletionNotification();
      }
      notifyListeners(); // Importante: actualiza el reloj en la UI cada segundo
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _actualizarEstadoVideos();
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