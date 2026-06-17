import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class DialogGeneral extends StatelessWidget {
  final String title;    // Título del diálogo
  final Widget content;  // Contenido dinámico (campos de texto, mensajes, etc.)
  final VoidCallback onSave; // Acción al presionar el botón de guardar
  final String saveText; // Texto personalizado del botón de guardar (default: 'Guardar')

  const DialogGeneral({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    this.saveText = 'Guardar',
  });

  @override
  Widget build(BuildContext context) {
    // Ajusta los tamaños de fuente dinámicamente según el ancho de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = screenWidth < 350 ? 24.0 : 35.0;
    final btnSize = screenWidth < 350 ? 18.0 : 25.0;

    return AlertDialog(
      backgroundColor: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.rojo, width: 3),
      ),
      // --- TITULO --- 
      title: Text(title, style: TextStyle(
        color: Colores.rojo, 
        fontWeight: FontWeight.bold,
        fontSize: titleSize,
        fontFamily: 'Subtitulo')),
      content: content,
      actions: [
        // --- BOTÓN CANCELAR ---
        TextButton(
          onPressed: () => Navigator.pop(context), // Cierra el diálogo sin guardar
          child: Text(
            'Cancelar', 
            style: TextStyle(
              color: Colors.grey, 
              fontFamily: 'Subtitulo',
              fontWeight: FontWeight.bold, 
              fontSize: btnSize),
          ),
        ),
        // --- BOTÓN GUARDAR ---
        TextButton(
          onPressed: onSave, // Ejecuta la lógica guardada pasada por parámetro
          child: Text(
            saveText, 
            style: TextStyle(
              color: Colores.rojo, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Subtitulo',
              fontSize: btnSize),
          ),        
        ),
      ],
    );
  }
}