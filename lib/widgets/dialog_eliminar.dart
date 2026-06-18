import 'package:flutter/material.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogEliminar extends StatelessWidget {
  final String nombreLugar; 
  final VoidCallback onConfirm; 

  const DialogEliminar({
    super.key, 
    required this.nombreLugar, 
    required this.onConfirm
  });

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: 'ELiminar Lugar',
      saveText: 'Eliminar',
      onSave: onConfirm,
      content: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 18, color: Colors.black87), // Estilo base para todo el texto
          children: [
            const TextSpan(text: '¿Seguro que quieres borrar "'), // Texto normal
            TextSpan(
              text: nombreLugar, // Nombre del lugar
              style: const TextStyle(fontWeight: FontWeight.bold), // Negrita solo al nombre
            ),
            const TextSpan(text: '" de tu mapa?'), // Texto normal
          ],
        ),
        textAlign: TextAlign.start, 
      ),
    );
  }
}