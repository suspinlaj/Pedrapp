import 'package:flutter/material.dart';

class Registro {
  final DateTime fecha;
  final double segundosTotales;

  Registro({required this.fecha, required this.segundosTotales});
}

class CategoriaMarca {
  String nombre;
  IconData icono;
  double objetivo;
  List<Registro> historial;

  CategoriaMarca({
    required this.nombre,
    required this.icono,
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

  // --- LÓGICA DE PROGRESO TOTALMENTE NUEVA ---
  double get progreso {
    if (historial.isEmpty) return 0.0; 

    double mejor = mejorMarca;

    // 1. Si ya logró el objetivo, 100% de una.
    if (mejor <= objetivo) return 1.0; 

    // 2. Establecemos el punto 0% de la barra (el "peor tiempo de referencia").
    // Por ejemplo: si el objetivo es 60s, el 0% de la barra serán 90s.
    double peorReferencia = objetivo * 1.5; 
    
    // Si su peor marca real es AÚN MÁS LENTA que esa referencia, usamos su peor marca 
    // real como 0%. Si no, usamos la referencia para que siempre haya color en la barra.
    double puntoDePartida = peorMarca > peorReferencia ? peorMarca : peorReferencia;
    
    // 3. Calculamos la fórmula en base a ese punto de partida
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
}