import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/cancion_pomodoro.dart';

// LISTA CANCIONES DISPONIBLES
class CancionesData {
  static const List<CancionPomodoro> listaDeCanciones = [
    CancionPomodoro(
      id: 'ninguno', 
      nombre: 'Sin sonido', 
      assetPath: '', 
      icono: Icons.music_off,
    ),
    CancionPomodoro(
      id: 'minecraft', 
      nombre: 'Minecraft', 
      assetPath: 'assets/audio/minecraft.mp3', 
      icono: Icons.videogame_asset,
    ),
    CancionPomodoro(
      id: 'pokemon', 
      nombre: 'Pokemon', 
      assetPath: 'assets/audio/pokemon.mp3', 
      icono: Icons.catching_pokemon,
    ),
    CancionPomodoro(
      id: 'pajaritos', 
      nombre: 'Pajaritos', 
      assetPath: 'assets/audio/pajaritos.mp3', 
      icono: Icons.flutter_dash,
    ),
    CancionPomodoro(
      id: 'lluvia', 
      nombre: 'Lluvia', 
      assetPath: 'assets/audio/lluvia.mp3', 
      icono: Icons.cloudy_snowing,
    ),
    CancionPomodoro(
      id: 'lofi_1', 
      nombre: 'Lofi 1', 
      assetPath: 'assets/audio/bread.mp3', 
      icono: Icons.headphones,
    ),
    CancionPomodoro(
      id: 'lofi_2', 
      nombre: 'Lofi 2', 
      assetPath: 'assets/audio/rose.mp3', 
      icono: Icons.auto_awesome,
    ),
    CancionPomodoro(
      id: 'lofi_3', 
      nombre: 'Lofi 3', 
      assetPath: 'assets/audio/honey.mp3', 
      icono: Icons.music_note_sharp,
    ),
  ];
}