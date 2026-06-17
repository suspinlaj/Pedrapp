import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class DialogGeneral extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final String saveText;

  const DialogGeneral({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    this.saveText = 'Guardar',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 1. Fondo blanco
      backgroundColor: Colors.white, 
      
      // 2. Definimos el borde
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Un toque redondeado queda mejor
        side: const BorderSide(color: Colores.rojo, width: 3), // Borde rojo
      ),
      
      title: Text(title, style: const TextStyle(
        color: Colores.rojo, 
        fontWeight: FontWeight.bold,
        fontSize: 35,
        fontFamily: 'Subtitulo')),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar', 
            style: TextStyle(
              color: Colors.grey, 
              fontFamily: 'Subtitulo',
              fontWeight: FontWeight.bold, 
              fontSize: 25 // Para que coincida con el estilo de tus títulos
            ),
          ),
        ),
        TextButton(
          onPressed: onSave,
          child: Text(
            saveText, 
            style: const TextStyle(
              color: Colores.rojo, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Subtitulo',
              fontSize: 25 // <--- Aquí lo añades
            ),
          ),        
        ),
      ],
    );
  }
}