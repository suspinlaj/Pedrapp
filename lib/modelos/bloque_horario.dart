import 'package:flutter/material.dart';

// Definir modelo de datos para las franjas horarias
class BloqueHorario {
  String id;
  int diaSemana; // 1 = Lunes, 7 = Domingo
  TimeOfDay horaInicio;
  TimeOfDay horaFin;
  String titulo;
  Color colorEtiqueta;

  BloqueHorario({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.titulo,
    required this.colorEtiqueta,
  });

  // Convertir objeto a formato compatible con Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'diaSemana': diaSemana,
      'horaInicio': '${horaInicio.hour}:${horaInicio.minute}',
      'horaFin': '${horaFin.hour}:${horaFin.minute}',
      'titulo': titulo,
      'colorEtiqueta': colorEtiqueta.value, 
    };
  }

  // Crear objeto desde los datos descargados de Firebase
  factory BloqueHorario.fromFirebase(Map<String, dynamic> json) {
    final inicioParts = (json['horaInicio'] as String).split(':');
    final finParts = (json['horaFin'] as String).split(':');
    return BloqueHorario(
      id: json['id'],
      diaSemana: json['diaSemana'],
      horaInicio: TimeOfDay(hour: int.parse(inicioParts[0]), minute: int.parse(inicioParts[1])),
      horaFin: TimeOfDay(hour: int.parse(finParts[0]), minute: int.parse(finParts[1])),
      titulo: json['titulo'],
      colorEtiqueta: Color(json['colorEtiqueta']), 
    );
  }
}