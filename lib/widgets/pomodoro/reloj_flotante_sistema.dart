import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:pedrapp/core/colores.dart';

class RelojFlotanteSistema extends StatefulWidget {
  const RelojFlotanteSistema({super.key});

  @override
  State<RelojFlotanteSistema> createState() => _RelojFlotanteSistemaState();
}

class _RelojFlotanteSistemaState extends State<RelojFlotanteSistema> {
  String _tiempo = "00:00";
  bool _isFocusMode = true;
  bool _isRunning = false;
  bool _mostrarTemporal = false;

  Timer? _animacionTimer;
  Timer? _autodestruccionTimer;
  
  // OPTIMIZACIÓN: Creamos un puerto propio para escuchar directamente a la app
  final ReceivePort _overlayReceivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    
    // 1. Registramos nuestro puerto en la memoria del sistema
    IsolateNameServer.removePortNameMapping('overlay_pomodoro_port');
    IsolateNameServer.registerPortWithName(_overlayReceivePort.sendPort, 'overlay_pomodoro_port');

    // 2. Escuchamos por cable directo ultrarrápido (Bypass del plugin)
    _overlayReceivePort.listen((message) {
      if (message is String) {
        if (message.startsWith("SYNC|")) {
          List<String> partes = message.split("|");
          if (partes.length == 4 && mounted) {
            setState(() {
              _tiempo = partes[1];
              _isFocusMode = partes[2] == "true";
              _isRunning = partes[3] == "true";
            });
            _reiniciarBombaAutodestruccion();
          }
        } else if (message == "KILL") {
          // Orden directa de ejecución desde la app al cerrarse
          FlutterOverlayWindow.closeOverlay();
        }
      }
    });
  }

  void _reiniciarBombaAutodestruccion() {
    _autodestruccionTimer?.cancel();
    _autodestruccionTimer = Timer(const Duration(seconds: 4), () async {
      await FlutterOverlayWindow.closeOverlay();
    });
  }

  void _toggleTimer() {
    // Enviamos la orden de pausa a la app principal por cable directo
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('pomodoro_port');
    if (sendPort != null) {
      sendPort.send("TOGGLE");
    }
    
    setState(() {
      _isRunning = !_isRunning;
      
      if (_isRunning) {
        _mostrarTemporal = true;
        _animacionTimer?.cancel();
        _animacionTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _mostrarTemporal = false;
            });
          }
        });
      } else {
        _mostrarTemporal = false;
        _animacionTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animacionTimer?.cancel();
    _autodestruccionTimer?.cancel();
    // Limpiamos la memoria
    IsolateNameServer.removePortNameMapping('overlay_pomodoro_port');
    _overlayReceivePort.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorFondo = _isFocusMode ? Colores.rojo : Colores.amarillo;
    final colorLetra = _isFocusMode ? Colors.white : Colors.black87;
    final bool mostrarCapaOscura = !_isRunning || _mostrarTemporal;
    final IconData iconoAMostrar = !_isRunning ? Icons.play_arrow : Icons.pause;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _toggleTimer,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorFondo,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                _tiempo,
                style: TextStyle(
                  color: colorLetra,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  decoration: TextDecoration.none, 
                ),
              ),
            ),

            IgnorePointer(
              child: AnimatedOpacity(
                opacity: mostrarCapaOscura ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconoAMostrar,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}