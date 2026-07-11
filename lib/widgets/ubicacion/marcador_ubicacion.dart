import 'package:flutter/material.dart';


// Dibujar la chincheta y su etiqueta en el mapa

class MarcadorUbicacion extends StatelessWidget {
  final String nombre;      // texto que aparecerá en el bocadillito
  final bool soyYo;         // Si es true, ignorará el nombre y escribirá "Yo"
  final Color colorTema;    // color  para el borde y el icono

  const MarcadorUbicacion({
    super.key,
    required this.nombre,
    required this.soyYo,
    required this.colorTema,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      // evitar que el texto se corte si es muy largo y se sale de los bordes
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        
        // Etiqueta con el nombre
        Positioned(
          bottom: 42, 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // fondo
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorTema, width: 2), // Borde
            ),
            child: Text(
              soyYo ? "Yo" : nombre, // Inteligencia del texto según quién lo mire
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black),
            ),
          ),
        ),

        // PIN DE LA UBICACIÓN
        Icon(
          Icons.location_on, 
          color: colorTema, 
          size: 45 
        )
      ],
    );
  }
}