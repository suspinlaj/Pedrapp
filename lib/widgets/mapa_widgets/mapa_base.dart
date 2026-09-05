import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapaBase extends StatelessWidget {
  const MapaBase({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // opaxidad mapa
      opacity: 0.6, 
      child: TileLayer(
        // url mapa
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        // Identificar la aplicación para evitar bloqueos del servidor
        userAgentPackageName: 'com.ejemplo.pedrapp',
      ),
    );
  }
}