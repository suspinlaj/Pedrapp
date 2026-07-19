import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';

// Importar librerías para detectar plataforma web o móvil
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

// Definir clase principal para controlar la lógica del pomodoro
class PomodoroController extends ChangeNotifier with WidgetsBindingObserver {
  
  // Establecer tiempos por defecto al abrir la app
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;

  // Aplicar patrón Singleton para mantener un único controlador global
  static final PomodoroController _instance = PomodoroController._internal();
  factory PomodoroController() => _instance;

  // Declarar variables del temporizador
  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  
  Timer? _timer; 
  Timer? _latidoEnPausaTimer; 
  
  bool _isRunning = false; 
  bool _isFocusMode = true; 

  // Declarar variables del historial de estudio
  int minutosHoy = 0;
  int minutosTotales = 0;

  // Declarar controladores multimedia
  VideoPlayerController? estudioController;
  VideoPlayerController? descansoController;
  final AudioPlayer _musicPlayer = AudioPlayer(); 
  CancionPomodoro? _cancionSeleccionada;
  String? _rutaAudioCargada;

  // Declarar variables de sistema y comunicación nativa
  bool _isInitialized = false; 
  final ReceivePort _receivePort = ReceivePort(); 

  // Comprobar compatibilidad del dispositivo con burbujas flotantes nativas
  bool get _soportaBurbujaFlotante {
    if (kIsWeb) return false; 
    return Platform.isAndroid; 
  }

  // Definir métodos de acceso a las variables (Getters)
  int get focusMinutes => _focusMinutes;
  int get breakMinutes => _breakMinutes;
  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;
  bool get isFocusMode => _isFocusMode;
  bool get videoEstudioInicializado => estudioController?.value.isInitialized ?? false;
  bool get videoDescansoInicializado => descansoController?.value.isInitialized ?? false;
  CancionPomodoro? get cancionSeleccionada => _cancionSeleccionada;

  // Inicializar constructor interno privado
  PomodoroController._internal() {
    _secondsLeft = _defaultFocusMinutes * 60;
  }

  // Arrancar controlador al abrir la pantalla por primera vez
  void inicializar(BuildContext context) {
    if (_isInitialized) return; 

    // Registrar observador del ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);

    // Configurar conexión con la burbuja en dispositivos compatibles
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'pomodoro_port');
      
      // Escuchar señales de Play/Pausa desde el puerto nativo
      _receivePort.listen((message) {
        if (message == "TOGGLE") {
          startStopTimer(); 
        }
      });

      // Escuchar señales de Play/Pausa como respaldo desde el plugin
      FlutterOverlayWindow.overlayListener.listen((event) {
        if (event == "TOGGLE") {
          startStopTimer(); 
        }
      });
    }

    // Ejecutar servicios complementarios
    NotificacionesService.inicializar();
    _initializeVideos();
    _cargarHistorial();
    _cargarAjustesMusica(); 
    _configureAudioSession(); 

    _isInitialized = true;
  }

  // Detectar cierre abrupto de la aplicación
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Matar la burbuja si el usuario desliza la app para cerrarla
    if (state == AppLifecycleState.detached) {
      _matarRelojFlotante();
    }
  }

  // Liberar memoria al destruir el controlador
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _latidoEnPausaTimer?.cancel();
    
    // Cerrar el puerto de comunicación activo
    if (_soportaBurbujaFlotante) {
      IsolateNameServer.removePortNameMapping('pomodoro_port');
      _receivePort.close();
    }
    super.dispose();
  }

  // Enviar tiempo y estado actual al widget flotante invisible
  void _sincronizarRelojFlotante() async {
    if (!_soportaBurbujaFlotante) return; 

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      String paquete = "SYNC|${formatTime()}|$_isFocusMode|$_isRunning";
      overlayPort.send(paquete);
    }
  }

  // Forzar destrucción de la ventana flotante en el sistema operativo
  void _matarRelojFlotante() {
    if (!_soportaBurbujaFlotante) return; 

    final SendPort? overlayPort = IsolateNameServer.lookupPortByName('overlay_pomodoro_port');
    if (overlayPort != null) {
      overlayPort.send("KILL");
    }
    FlutterOverlayWindow.closeOverlay();
  }

  // Recuperar canción guardada en preferencias locales
  Future<void> _cargarAjustesMusica() async {
    final prefs = await SharedPreferences.getInstance();
    final String cancionGuardadaId = prefs.getString('pomodoro_musica_id') ?? 'ninguno';
    
    _cancionSeleccionada = CancionesData.listaDeCanciones.firstWhere(
      (c) => c.id == cancionGuardadaId,
      orElse: () => CancionesData.listaDeCanciones.first, 
    );
    notifyListeners(); 
  }

  // Configurar sesión de audio para el sistema operativo
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Pausar reproducción automáticamente al recibir interrupciones
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_musicPlayer.playing) {
          _musicPlayer.pause();
        }
      }
    });
  }

  // Reproducir o detener archivo de audio según estado del temporizador
  Future<void> _gestionarMusicaDeFondo() async {
    // Detener música si no hay pista válida o el reloj está pausado
    if (_cancionSeleccionada == null || 
        _cancionSeleccionada!.id == 'ninguno' || 
        !_isFocusMode || 
        !_isRunning) {
      if (_musicPlayer.playing) {
        await _musicPlayer.stop();
      }
      return;
    }

    // Iniciar reproducción en bucle
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

  // Guardar nueva selección musical en persistencia y aplicar cambios
  Future<void> seleccionarCancion(CancionPomodoro cancion) async {
    _cancionSeleccionada = cancion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pomodoro_musica_id', cancion.id);
    if (_isFocusMode && _isRunning) _gestionarMusicaDeFondo();
    notifyListeners();
  }

  // Alternar reproducción de vídeos de fondo según modo actual
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

  // Recuperar historial de estudio acumulado
  Future<void> _cargarHistorial() async {
    final datos = await PomodoroService.cargarHistorial();
    minutosTotales = datos['total'] ?? 0;
    minutosHoy = datos['hoy'] ?? 0;
    notifyListeners();
  }

  // Sumar bloque de minutos finalizado al historial persistente
  Future<void> _sumarTiempoAlHistorial(int minutos) async {
    minutosTotales += minutos;
    minutosHoy += minutos;
    notifyListeners();
    PomodoroService.sumarTiempoAlHistorial(minutos);
  }

  // Cargar activos mp4 en memoria
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

  // Alternar estado global del temporizador
  void startStopTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  // Iniciar conteo regresivo
  void _startTimer() {
    _isRunning = true;
    _latidoEnPausaTimer?.cancel(); 
    
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo();
    _sincronizarRelojFlotante(); 

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        // Restar un segundo al contador activo
        _secondsLeft--; 
        _showTimerNotification(); 
      } else {
        // Detener conteo al llegar a cero
        timer.cancel();
        
        // Sumar tiempo si el modo era estudio
        if (_isFocusMode) _sumarTiempoAlHistorial(_focusMinutes); 
        
        // Alternar modo de trabajo
        _isFocusMode = !_isFocusMode; 
        
        // Reiniciar tiempo al nuevo modo correspondiente
        _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60; 
        
        _isRunning = false;
        _actualizarEstadoVideos();
        _gestionarMusicaDeFondo(); 
        _showCompletionNotification(); 
        
        // --- CORRECCIÓN: Iniciar latido de pausa automáticamente al terminar el bloque ---
        if (_soportaBurbujaFlotante) {
          _latidoEnPausaTimer?.cancel();
          _latidoEnPausaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
            _sincronizarRelojFlotante();
          });
        }
      }
      
      // Actualizar información visual global
      _sincronizarRelojFlotante(); 
      notifyListeners(); 
    });
  }

  // Pausar temporizador en ejecución
  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _actualizarEstadoVideos();
    _gestionarMusicaDeFondo(); 
    NotificacionesService.cancelar();
    _sincronizarRelojFlotante(); 
    notifyListeners();

    // Mantener comunicación viva enviando latidos mientras está pausado
    if (_soportaBurbujaFlotante) {
      _latidoEnPausaTimer?.cancel();
      _latidoEnPausaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sincronizarRelojFlotante();
      });
    }
  }

  // Reiniciar estado y valores a la configuración por defecto
  void resetTimer() {
    _stopTimer();
    _latidoEnPausaTimer?.cancel();
    _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
    _matarRelojFlotante(); 
    notifyListeners();
  }

  // Modificar duración objetivo desde los selectores interactivos
  void updateDuration({required bool isFocus, required int minutes}) {
    // Aplicar límites numéricos permitidos
    if (isFocus) {
      _focusMinutes = minutes.clamp(1, 180);
    } else {
      _breakMinutes = minutes.clamp(1, 180);
    }

    // Sincronizar tiempo restante si el reloj está detenido y coincide el modo
    if (_isFocusMode && isFocus) {
      _secondsLeft = _focusMinutes * 60;
    } else if (!_isFocusMode && !isFocus) {
      _secondsLeft = _breakMinutes * 60;
    }
    notifyListeners();
  }

  // Transformar valor de segundos totales a formato texto MM:SS
  String formatTime() {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Lanzar notificación de sistema del progreso
  void _showTimerNotification() {
    final title = _isFocusMode ? 'Pomodoro: Estudio' : 'Pomodoro: Descanso';
    final body = 'Tiempo restante: ${formatTime()}';
    NotificacionesService.mostrarEnProgreso(title, body);
  }

  // Lanzar notificación de sistema de bloque finalizado
  void _showCompletionNotification() {
    final title = _isFocusMode ? '¡A estudiar vago!' : 'Hora de tu esperado descansito awa';
    final body = _isFocusMode ? '¡Deja los juegos!, vuelta a estudiar jaja' : '¡Tiempo de hablar a la besto novia!';
    NotificacionesService.mostrarCompletado(title, body);
  }
}