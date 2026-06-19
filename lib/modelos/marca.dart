// lib/modelos/modelo_marca.dart

import 'package:flutter/material.dart'; // <-- Añadido para poder usar IconData

class Registro {
  final DateTime fecha;
  final double segundosTotales;

  Registro({required this.fecha, required this.segundosTotales});
}

class CategoriaMarca {
  String nombre;
  IconData icono; // <-- Nuevo campo para el icono
  double objetivo;
  List<Registro> historial;

  CategoriaMarca({
    required this.nombre,
    required this.icono, // <-- Lo pedimos aquí
    required this.objetivo,
    List<Registro>? historial,
  }) : historial = historial ?? [];

  // Busca el tiempo más bajo (el mejor)
  double get mejorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a < b ? a : b);
  }

  // Busca el tiempo más alto (el peor/inicial)
  double get peorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a > b ? a : b);
  }

  // Calcula cómo de llena debe estar la barra (de 0.0 a 1.0)
  double get progreso {
    if (historial.isEmpty || historial.length == 1) return 0.0; 
    double mejor = mejorMarca;
    double peor = peorMarca;
    
    if (mejor <= objetivo) return 1.0; 
    if (peor == objetivo) return 0.0; 
    
    double progresoCalculado = (peor - mejor) / (peor - objetivo);
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
}