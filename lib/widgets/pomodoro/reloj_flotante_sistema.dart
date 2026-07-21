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
  // variables y  temporizador
  String _tiempo = "00:00";
  bool _isFocusMode = true;
  bool _isRunning = false;
  bool _mostrarTemporal = false;

  Timer? _animacionTimer;
  Timer? _autodestruccionTimer;
  
  // Crear un puerto de recepción propio para la comunicación directa con la aplicación
  final ReceivePort _overlayReceivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    
    // Eliminar cualquier registro previo del puerto para evitar colisiones
    IsolateNameServer.removePortNameMapping('overlay_pomodoro_port');
    
    // Registrar el puerto de envío en la memoria global del sistema operativo
    IsolateNameServer.registerPortWithName(_overlayReceivePort.sendPort, 'overlay_pomodoro_port');

    // Escuchar mensajes entrantes por el canal directo de memoria de Dart
    _overlayReceivePort.listen((message) {
      if (message is String) {
        // Procesar la cadena de sincronización de tiempo y estados recibida
        if (message.startsWith("SYNC|")) {
          List<String> partes = message.split("|");
          if (partes.length == 4 && mounted) {
            // Actualizar el estado visual del widget flotante con los nuevos datos
            setState(() {
              _tiempo = partes[1];
              _isFocusMode = partes[2] == "true";
              _isRunning = partes[3] == "true";
            });
            // Extender el tiempo de vida de la ventana tras la confirmación de la app viva
            _reiniciarBombaAutodestruccion();
          }
        } else if (message == "KILL") {
          // Destruir la ventana flotante de inmediato por orden directa del proceso principal
          FlutterOverlayWindow.closeOverlay();
        }
      }
    });
  }

  // Programar un temporizador de seguridad que cierra el widget flotante si la aplicación deja de responder
  void _reiniciarBombaAutodestruccion() {
    _autodestruccionTimer?.cancel();
    _autodestruccionTimer = Timer(const Duration(seconds: 4), () async {
      // Cerrar ventana del sistema al cumplirse el tiempo de inactividad de la comunicación
      await FlutterOverlayWindow.closeOverlay();
    });
  }

  void _toggleTimer() {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('pomodoro_port');
    if (sendPort != null) {
      sendPort.send("TOGGLE");
    }
    
    // Actualizar el estado 
    setState(() {
      _isRunning = !_isRunning;
      
      if (_isRunning) {
        // icono pausa
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
        // mantener visible el icono de pausa
        _mostrarTemporal = false;
        _animacionTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    // Cancelar los contadores de tiempo activos para prevenir fugas de memoria
    _animacionTimer?.cancel();
    _autodestruccionTimer?.cancel();
    
    IsolateNameServer.removePortNameMapping('overlay_pomodoro_port');
    _overlayReceivePort.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colores segun si se está estudiando o descansando
    final colorFondo = _isFocusMode ? Colores.rojo : Colores.amarillo;
    final colorLetra = _isFocusMode ? Colors.white : Colors.white;
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