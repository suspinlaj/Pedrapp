import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedrapp/servicios/lugar_service.dart';

class PomodoroService {
  // --- Leer historial guardado de Firebase ---
  static Future<Map<String, int>> cargarHistorial() async {
    int totales = 0;
    int hoyMin = 0;

    try {
      final String id = await LugarService.getDeviceId();
      final String hoy = DateTime.now().toIso8601String().substring(0, 10);
      
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        totales = data['pomodoro_total'] ?? 0;
        
        if (data['pomodoro_dias'] != null) {
          hoyMin = data['pomodoro_dias'][hoy] ?? 0;
        }
      }
    } catch (e) {
      debugPrint("Error cargando historial de Firebase: $e");
    }

    return {'total': totales, 'hoy': hoyMin};
  }

  // --- Sumar y guardar minutos en Firebase ---
  static Future<void> sumarTiempoAlHistorial(int minutos) async {
    try {
      final String id = await LugarService.getDeviceId();
      final String hoy = DateTime.now().toIso8601String().substring(0, 10);

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
}