import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedrapp/core/colores.dart';

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
  int _secondsLeft = _defaultFocusMinutes * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
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
    final title = _isFocusMode ? 'Pomodoro: estudio' : 'Pomodoro: descanso';
    final body = 'Tiempo restante: ${_formatTime(_secondsLeft)}';

    try {
      await _notificationsPlugin.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
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
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _showCompletionNotification() async {
    final title = _isFocusMode ? '¡Tiempo de estudio terminado!' : '¡Tiempo de descanso terminado!';
    final body = _isFocusMode ? 'Empieza tu descanso de ${_breakMinutes} min' : 'Empieza tu sesión de estudio de ${_focusMinutes} min';

    try {
      await _notificationsPlugin.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'pomodoro_channel',
            'Pomodoro',
            channelDescription: 'Notificaciones del temporizador',
            importance: Importance.low,
            priority: Priority.low,
            visibility: NotificationVisibility.private,
            showWhen: false,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
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
    // Agrega un cero a la izquierda si es menor de 10
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Importante cancelar el timer para evitar memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isFocusMode ? Colors.redAccent[100] : Colors.teal[100],
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isFocusMode ? '¡A Enfocarse!' : 'Tiempo de Descanso',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isFocusMode ? Colors.red[900] : Colors.teal[900],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _formatTime(_secondsLeft),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DurationSelector(
                  label: 'Estudio',
                  value: _focusMinutes,
                  onChanged: (value) => _updateDuration(isFocus: true, minutes: value),
                ),
                const SizedBox(width: 16),
                _DurationSelector(
                  label: 'Descanso',
                  value: _breakMinutes,
                  onChanged: (value) => _updateDuration(isFocus: false, minutes: value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startStopTimer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 30,
                  onPressed: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => onChanged(value - 5),
              ),
              Text('$value min', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => onChanged(value + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}