import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedrapp/servicios/lugar_service.dart';

class PomodoroPantalla extends StatefulWidget {
  const PomodoroPantalla({super.key});

  @override
  State<PomodoroPantalla> createState() => _PomodoroPantallaState();
}

class _PomodoroPantallaState extends State<PomodoroPantalla> {
  static const int _defaultFocusMinutes = 40;
  static const int _defaultBreakMinutes = 5;
  static const int _notificationId = 1;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  int _focusMinutes = _defaultFocusMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  late int _secondsLeft;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true;

  // --- VARIABLES DEL HISTORIAL ---
  int _minutosHoy = 0;
  int _minutosTotales = 0;

  // --- CONTROLADORES PARA LOS VIDEOS TIPO GIF ---
  VideoPlayerController? _estudioController;
  VideoPlayerController? _descansoController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _defaultFocusMinutes * 60;
    _initializeNotifications();
    _initializeVideos();
    _cargarHistorial(); // --- Cargamos los datos del historial al abrir la pantalla ---
  }

  // --- FUNCIÓN MAESTRA: Controla qué vídeo se mueve y cuál se congela ---
  void _actualizarEstadoVideos() {
    final bool mostrarEstudio = _isFocusMode && _isRunning;
    
    if (mostrarEstudio) {
      _descansoController?.pause();
      _estudioController?.play();
    } else {
      // Si está pausado, recién abierto o en descanso, el vídeo de descanso cobra vida
      _estudioController?.pause();
      _descansoController?.play();
    }
  }

  // --- Leer historial guardado de Firebase ---
  Future<void> _cargarHistorial() async {
    try {
      final String id = await LugarService.getDeviceId();
      final String hoy = DateTime.now().toIso8601String().substring(0, 10);
      
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        int total = data['pomodoro_total'] ?? 0;
        int hoyMin = 0;
        
        if (data['pomodoro_dias'] != null) {
          hoyMin = data['pomodoro_dias'][hoy] ?? 0;
        }
        
        setState(() {
          _minutosTotales = total;
          _minutosHoy = hoyMin;
        });
      }
    } catch (e) {
      debugPrint("Error cargando historial de Firebase: $e");
    }
  }

  // --- Sumar y guardar minutos en Firebase ---
  Future<void> _sumarTiempoAlHistorial(int minutos) async {
    try {
      final String id = await LugarService.getDeviceId();
      final String hoy = DateTime.now().toIso8601String().substring(0, 10);

      setState(() {
        _minutosTotales += minutos;
        _minutosHoy += minutos;
      });

      await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
        'pomodoro_total': FieldValue.increment(minutos),
        'pomodoro_dias': {
          hoy: FieldValue.increment(minutos)
        }
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint("Error subiendo historial a Firebase: $e");
    }
  }

  void _initializeVideos() {
    _estudioController = VideoPlayerController.asset(
      'assets/images/pomodoro_estudio.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _estudioController?.setLooping(true); 
        _estudioController?.setVolume(0.0);   
        _actualizarEstadoVideos(); 
        setState(() {});
      });

    _descansoController = VideoPlayerController.asset(
      'assets/images/pomodoro_descanso.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _descansoController?.setLooping(true); 
        _descansoController?.setVolume(0.0);   
        _actualizarEstadoVideos(); 
        setState(() {});
      });
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Inicializa el motor de notificaciones
      await _notificationsPlugin.initialize(settings);

      // --- MAGIA AÑADIDA: Pedir permisos automáticamente al usuario ---
      
      // 1. Si el móvil es Android, pedimos permiso a la manera de Android (Obligatorio en Android 13+)
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        // Si por casualidad te sigue dando error de importación, asegúrate 
        // de tener importado 'dart:io' arriba del todo.
        await androidPlugin?.requestNotificationsPermission();
      } 
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
  }

  void _startStopTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    
    _actualizarEstadoVideos(); 

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          _showTimerNotification();
        } else {
          timer.cancel();

          // --- SI TERMINA UN BLOQUE DE ESTUDIO, SUMAMOS AL HISTORIAL ---
          if (_isFocusMode) {
            _sumarTiempoAlHistorial(_focusMinutes);
          }

          _isFocusMode = !_isFocusMode;
          _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
          _isRunning = false;
          
          _actualizarEstadoVideos(); 
          _showCompletionNotification();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    
    _actualizarEstadoVideos(); 
    _cancelNotification();
  }

  void _resetTimer() {
    _stopTimer(); 
    setState(() {
      _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
    });
  }

  Future<void> _showTimerNotification() async {
    final title = _isFocusMode ? 'Pomodoro: Estudio' : 'Pomodoro: Descanso';
    final body = 'Tiempo restante: ${_formatTime(_secondsLeft)}';

    try {
      await _notificationsPlugin.show(
        _notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pomodoro_channel',
            'Pomodoro',
            channelDescription: 'Notificaciones del temporizador',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.private,
            showWhen: false,
            onlyAlertOnce: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _showCompletionNotification() async {
    final title = _isFocusMode ? '¡A estudiar vago!' : '¡Tiempo de hablar a la besto novia!';
    final body = _isFocusMode ? 'Hora de dejar los juegos, de vuelta a estudiar jasjas' : 'Hora de tu amado descansito uwu';

    try {
      await _notificationsPlugin.show(
        _notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pomodoro_channel',
            'Pomodoro',
            channelDescription: 'Notificaciones del temporizador',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _cancelNotification() async {
    try {
      await _notificationsPlugin.cancel(_notificationId);
    } catch (_) {}
  }

  void _updateDuration({required bool isFocus, required int minutes}) {
    setState(() {
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
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Diálogo para mostrar el historial ---
  void _mostrarHistorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colores.rojo, width: 4),
        ),
        title: const Text(
          'HistoriaL de Estudio',
          style: TextStyle(color: Colores.rojo, fontFamily: 'Titulo', fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colores.rojo, size: 50),
            const SizedBox(height: 20),
            Text('Hoy: $_minutosHoy minutos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Total histórico: $_minutosTotales minutos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Genial', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.bold, fontSize: 18)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _estudioController?.dispose();
    _descansoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTema = _isFocusMode ? Colores.rojo : Colores.amarillo;
    final bool mostrarEstudio = _isFocusMode && _isRunning;

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
            onPressed: _mostrarHistorial,
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
              width: 280, 
              height: 270,
              child: mostrarEstudio
                  ? (_estudioController != null && _estudioController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _estudioController!.value.aspectRatio,
                          child: VideoPlayer(_estudioController!),
                        )
                      : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colores.rojo)))
                  : (_descansoController != null && _descansoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _descansoController!.value.aspectRatio,
                          child: VideoPlayer(_descansoController!),
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
                    
                    // --- TÍTULO DE ESTADO ---
                    Text(
                      _isFocusMode ? '¡a estudiar vago!' : 'tiempo de haBLar a La Besto novia',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Titulo',
                        letterSpacing: 1.5,
                        color: colorTema,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // --- RELOJ PRINCIPAL ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorTema, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: colorTema.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5)
                          )
                        ]
                      ),
                      child: Text(
                        _formatTime(_secondsLeft),
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: colorTema,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // --- SELECTORES DE TIEMPO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DurationSelector(
                          label: 'Estudio',
                          value: _focusMinutes,
                          colorTema: Colores.rojo,
                          onChanged: (value) => _updateDuration(isFocus: true, minutes: value),
                        ),
                        const SizedBox(width: 16),
                        _DurationSelector(
                          label: 'Descanso',
                          value: _breakMinutes,
                          colorTema: Colores.amarillo,
                          onChanged: (value) => _updateDuration(isFocus: false, minutes: value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // --- BOTONES DE CONTROL ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- BOTÓN MÚSICA (FUTURO) ---
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selector de música próximamente...', textAlign: TextAlign.center),
                                backgroundColor: Colores.rojo,
                                duration: Duration(seconds: 2),
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
                            child: Icon(Icons.music_note, color: Colores.gris, size: 30),
                          ),
                        ),
                        const SizedBox(width: 15),

                        // --- BOTÓN INICIAR / PAUSAR ---
                        GestureDetector(
                          onTap: _startStopTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            decoration: BoxDecoration(
                              color: colorTema, 
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colores.gris, width: 3),
                            ),
                            child: Text(
                              _isRunning ? 'Pausar' : 'Iniciar',
                              style: TextStyle(
                                color: _isFocusMode ? Colors.white : Colors.black87, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 20
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),

                        // --- BOTÓN REINICIAR ---
                        GestureDetector(
                          onTap: _resetTimer,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colores.gris, width: 3),
                            ),
                            child: Icon(Icons.refresh, color: Colores.gris, size: 30),
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
  }
}

// --- WIDGET AISLADO: SELECTOR DE TIEMPO ---
class _DurationSelector extends StatelessWidget {
  final String label;
  final int value;
  final Color colorTema;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.label,
    required this.value,
    required this.colorTema,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colores.gris, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colorTema)),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                color: Colores.gris,
                onPressed: () {
                  // LÓGICA INTELIGENTE AL RESTAR: Si está en 5, salta al 1 en lugar de ir al 0
                  int nextValue = (value <= 5) ? 1 : value - 5;
                  onChanged(nextValue);
                },
              ),
              Text('$value min', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: colorTema,
                onPressed: () {
                  // LÓGICA INTELIGENTE AL SUMAR: Si está en 1, salta al 5 en lugar de ir al 6
                  int nextValue = (value == 1) ? 5 : value + 5;
                  onChanged(nextValue);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}