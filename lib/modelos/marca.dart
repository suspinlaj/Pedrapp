import 'package:flutter/material.dart';

class Registro {
  final DateTime fecha;
  final double segundosTotales;

  Registro({required this.fecha, required this.segundosTotales});
}

class CategoriaMarca {
  String id; // <-- Añadimos un ID único para Firebase
  String nombre;
  IconData icono;
  double objetivo;
  List<Registro> historial;

  CategoriaMarca({
    required this.id, // <-- Lo pedimos aquí
    required this.nombre,
    required this.icono,
    required this.objetivo,
    List<Registro>? historial,
  }) : historial = historial ?? [];

  // ... (Tus funciones de mejorMarca, peorMarca y progreso se quedan exactamente igual)
  double get mejorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a < b ? a : b);
  }

  double get peorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a > b ? a : b);
  }

  double get progreso {
    if (historial.isEmpty) return 0.0; 
    double mejor = mejorMarca;
    if (mejor <= objetivo) return 1.0; 
    double peorReferencia = objetivo * 1.5; 
    double puntoDePartida = peorMarca > peorReferencia ? peorMarca : peorReferencia;
    double progresoCalculado = (puntoDePartida - mejor) / (puntoDePartida - objetivo);
    return progresoCalculado.clamp(0.0, 1.0); 
  }
  
  static String formatearTiempo(double totalSegundos) {
    if (totalSegundos == 0) return "--:--";
    int minutos = (totalSegundos / 60).floor();
    double segundos = totalSegundos % 60;
    String minsStr = minutos.toString().padLeft(2, '0');
    String secsStr = segundos.toStringAsFixed(1).padLeft(4, '0'); 
    return "$minsStr:$secsStr";
  }

  // --- LAS DOS NUEVAS FUNCIONES PARA FIREBASE ---
  
  // 1. Convierte la categoría a un mapa para mandarlo a Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'nombre': nombre,
      'objetivo': objetivo,
      // Guardamos el historial como una lista de mapas
      'historial': historial.map((r) => {
        'fecha': r.fecha.toIso8601String(),
        'segundosTotales': r.segundosTotales,
      }).toList(),
    };
  }

  // 2. Transforma lo que nos devuelve Firebase en una categoría de Flutter
  static CategoriaMarca fromFirebase(Map<String, dynamic> json, IconData iconoAsignado) {
    var listaHistorial = json['historial'] as List? ?? [];
    List<Registro> historialParseado = listaHistorial.map((r) {
      return Registro(
        fecha: DateTime.parse(r['fecha']),
        segundosTotales: (r['segundosTotales'] as num).toDouble(),
      );
    }).toList();

    return CategoriaMarca(
      id: json['id'],
      nombre: json['nombre'],
      icono: iconoAsignado,
      objetivo: (json['objetivo'] as num).toDouble(),
      historial: historialParseado,
    );
  }
}