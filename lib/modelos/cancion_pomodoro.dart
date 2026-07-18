// lib/models/cancion_pomodoro.dart
import 'package:flutter/material.dart';

class CancionPomodoro {
  final String id;
  final String nombre;
  final String assetPath;
  final IconData icono;

  const CancionPomodoro({
    required this.id,
    required this.nombre,
    required this.assetPath,
    required this.icono,
  });
}