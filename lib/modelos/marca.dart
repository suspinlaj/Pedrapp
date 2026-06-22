import 'package:flutter/material.dart';

class Registro {
  final DateTime fecha; // El día y la hora exacta en la que hizo el tiempo
  final double segundosTotales; // Marca guardada

  Registro({required this.fecha, required this.segundosTotales});
}

class CategoriaMarca {
  String id; 
  String nombre; 
  IconData icono; 
  double objetivo; 
  List<Registro> historial;

  CategoriaMarca({
    required this.id, 
    required this.nombre,
    required this.icono,
    required this.objetivo,
    List<Registro>? historial,
  }) : historial = historial ?? [];

  // Busca y devuelve el tiempo más bajo (el más rápido) de toda la lista.
  // Si la lista está vacía, devuelve 0 para evitar errores.
  double get mejorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a < b ? a : b);
  }

  // Busca y devuelve el tiempo más alto (el más lento) de toda la lista.
  // Si la lista está vacía, devuelve 0 para evitar errores.
  double get peorMarca {
    if (historial.isEmpty) return 0;
    return historial.map((e) => e.segundosTotales).reduce((a, b) => a > b ? a : b);
  }

  // Calcula el porcentaje de avance para rellenar la barra visual.
  // Devuelve siempre un valor entre 0.0 (vacío) y 1.0 (lleno).
  double get progreso {
    if (historial.isEmpty) return 0.0; // Si no hay datos, barra a cero.
    double mejor = mejorMarca;
    
    if (mejor <= objetivo) return 1.0; // Si ya se ha conseguido el objetivo, barra al 100%.
    
    // Compara la mejor marca con la peor, tomando como referencia un 150% del objetivo.
    double peorReferencia = objetivo * 1.5; 
    double puntoDePartida = peorMarca > peorReferencia ? peorMarca : peorReferencia;
    double progresoCalculado = (puntoDePartida - mejor) / (puntoDePartida - objetivo);
    
    //  asegura que el valor nunca baje de 0 ni pase de 1.
    return progresoCalculado.clamp(0.0, 1.0); 
  }
  
  // convierte segundos a formato reloj (Ej: 01:05.0)
  static String formatearTiempo(double totalSegundos) {
    if (totalSegundos == 0) return "--:--"; // Texto por defecto si no hay tiempo
    int minutos = (totalSegundos / 60).floor(); // Saca los minutos enteros
    double segundos = totalSegundos % 60; // Saca el "sobrante" en segundos
    
    // Añade ceros a la izquierda para que siempre ocupe el mismo espacio visual (Ej: 05 en vez de 5)
    String minsStr = minutos.toString().padLeft(2, '0');
    String secsStr = segundos.toStringAsFixed(1).padLeft(4, '0'); 
    
    return "$minsStr:$secsStr";
  }

  // MPAQUETAR DATOS
  // Transforma en un Map para que firebase pueda guardarlo
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'nombre': nombre,
      'objetivo': objetivo,
      // lista de registros la convierte a lista de texto
      'historial': historial.map((r) => {
        'fecha': r.fecha.toIso8601String(),
        'segundosTotales': r.segundosTotales,
      }).toList(),
    };
  }

  // DESEMPAQUETAR DATOS
  // Coge los datos de firebase para que la app lo pueda dibujar.
  static CategoriaMarca fromFirebase(Map<String, dynamic> json, IconData iconoAsignado) {
    // Saca la lista del historial y, si está vacía, pone un [] por defecto.
    var listaHistorial = json['historial'] as List? ?? [];
    
    // Convierte los textos del historial de Firebase a objetos Registro 
    List<Registro> historialParseado = listaHistorial.map((r) {
      return Registro(
        fecha: DateTime.parse(r['fecha']),
        segundosTotales: (r['segundosTotales'] as num).toDouble(), 
      );
    }).toList();

    // modelo ya montado con los datos de Firebase
    return CategoriaMarca(
      id: json['id'],
      nombre: json['nombre'],
      icono: iconoAsignado,
      objetivo: (json['objetivo'] as num).toDouble(),
      historial: historialParseado,
    );
  }
}