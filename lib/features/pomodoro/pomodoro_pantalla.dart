import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedrapp/core/colores.dart';
// --- NUEVO IMPORT: Añadimos el paquete para reproducir vídeo nativo ---
import 'package:video_player/video_player.dart';

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

  // --- CONTROLADORES PARA LOS VIDEOS TIPO GIF ---
  VideoPlayerController? _estudioController;
  VideoPlayerController? _descansoController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _defaultFocusMinutes * 60;
    _initializeNotifications();
    _initializeVideos(); // --- Inicializamos las animaciones al arrancar ---
  }

  // --- NUEVA FUNCIÓN: Inicializa los vídeos en modo silencioso y compartido ---
  void _initializeVideos() {
    // Vídeo de estudio (Corregida la ruta a estudio.mp4)
    _estudioController = VideoPlayerController.asset(
      'assets/images/pomodoro_estudio.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _estudioController?.setLooping(true); // Bucle infinito tipo GIF
        _estudioController?.setVolume(0.0);   // Completamente mudo
        _estudioController?.play();           // Auto-play automático
        setState(() {});
      });

    // Vídeo de descanso
    _descansoController = VideoPlayerController.asset(
      'assets/images/pomodoro_descanso.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _descansoController?.setLooping(true); // Bucle infinito tipo GIF
        _descansoController?.setVolume(0.0);   // Completamente mudo
        _descansoController?.play();           // Auto-play automático
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
      await _notificationsPlugin.initialize(settings);
    } catch (_) {}
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          // Actualiza la notificación en vivo (silenciosamente)
          _showTimerNotification();
        } else {
          timer.cancel();
          _isFocusMode = !_isFocusMode;
          _secondsLeft = _isFocusMode ? _focusMinutes * 60 : _breakMinutes * 60;
          _isRunning = false;
          _showCompletionNotification();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
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
    final title = _isFocusMode ? '¡a estudiar vago!' : '¡tiempo de hablar \na la besto novia!';
    final body = _isFocusMode ? 'Empieza tu descanso de $_breakMinutes min' : 'Empieza tu sesión de estudio de $_focusMinutes min';

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
            importance: Importance.high, // Alta para que suene/vibre al terminar
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

  @override
  void dispose() {
    _timer?.cancel(); 
    // --- OPTIMIZACIÓN CRÍTICA: Destruimos los controladores de vídeo para liberar RAM ---
    _estudioController?.dispose();
    _descansoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el color de acento según el modo en el que estemos
    final colorTema = _isFocusMode ? Colores.rojo : Colores.amarillo;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio al estilo del resto de la app
      
      // --- BARRA SUPERIOR ESTILO PEDRAPP ---
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
      ),
      
      // --- CUERPO PRINCIPAL EN STACK ---
      body: Stack(
        children: [
          // --- CAPA 1 (FONDO): EL REPRODUCTOR DE VÍDEO ---
          Positioned(
            bottom: 0, 
            right: 0,  
            child: SizedBox(
              width: 280, 
              height: 270,
              child: _isFocusMode
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
                              color: _isRunning ? Colores.amarillo : colorTema,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colores.gris, width: 3),
                            ),
                            child: Text(
                              _isRunning ? 'Pausar' : 'Iniciar',
                              style: TextStyle(
                                color: _isRunning ? Colors.black87 : Colors.white, 
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
                onPressed: () => onChanged(value - 5),
              ),
              Text('$value min', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: colorTema,
                onPressed: () => onChanged(value + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}