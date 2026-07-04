import 'package:flutter/material.dart';

class MarcadorUbicacion extends StatelessWidget {
  final String nombre;
  final bool soyYo;
  final Color colorTema;

  const MarcadorUbicacion({
    super.key,
    required this.nombre,
    required this.soyYo,
    required this.colorTema,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 42, 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorTema, width: 2),
            ),
            child: Text(
              soyYo ? "Yo" : nombre, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black),
            ),
          ),
        ),
        Icon(
          Icons.location_on, 
          color: colorTema, 
          size: 45
        )
      ],
    );
  }
}