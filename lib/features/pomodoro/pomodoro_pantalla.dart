import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedrapp/core/colores.dart';

class PomodoroPantalla extends StatefulWidget {
  const PomodoroPantalla({super.key});

  @override
  State<PomodoroPantalla> createState() => _PomodoroPantallaState();
}

class _PomodoroPantallaState extends State<PomodoroPantalla> {
  // 25 minutos de enfoque en segundos
  static const int focusTime = 25 * 60; 
  // 5 minutos de descanso en segundos
  static const int breakTime = 5 * 60; 

  int _secondsLeft = focusTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true;

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
        } else {
          // El tiempo terminó, alternamos entre enfoque y descanso
          _isFocusMode = !_isFocusMode;
          _secondsLeft = _isFocusMode ? focusTime : breakTime;
          _stopTimer();
          // Aquí podrías añadir una alerta sonora o vibración
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _secondsLeft = _isFocusMode ? focusTime : breakTime;
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
            // Indicador de modo
            Text(
              _isFocusMode ? '¡A Enfocarse!' : 'Tiempo de Descanso',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: _isFocusMode ? Colors.red[900] : Colors.teal[900],
              ),
            ),
            const SizedBox(height: 40),
            // El Cronómetro
            Text(
              _formatTime(_secondsLeft),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()], // Evita que los números "bailen"
              ),
            ),
            const SizedBox(height: 40),
            // Botones de Control
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