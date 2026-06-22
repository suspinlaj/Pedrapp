import 'package:flutter/material.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogEliminar extends StatelessWidget {
  final String titulo; // Título de la ventana 
  final String nombreItem; // El elemento concreto a borrar
  final String finalMensaje; // mensaje
  final VoidCallback onConfirm; 

  const DialogEliminar({
    super.key, 
    required this.titulo,
    required this.nombreItem,
    required this.finalMensaje,
    required this.onConfirm
  });

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: titulo, // título dinámico que le hayamos pasado
      saveText: 'Eliminar', //boton eliminar
      onSave: onConfirm,
      
      content: Text.rich(
        TextSpan(
          // Estilo base para todo el bloque de texto 
          style: const TextStyle(fontSize: 18, color: Colors.black87),
          children: [
            // inicio de la pregunta (Texto normal)
            const TextSpan(text: '¿Seguro que quieres borrar "'),
            // El nombre del ítem
            TextSpan(
              text: nombreItem, 
              style: const TextStyle(fontWeight: FontWeight.bold), 
            ),
            //  Texto final (Texto normal)
            TextSpan(text: '" $finalMensaje'), 
          ],
        ),
        textAlign: TextAlign.start, 
      ),
    );
  }
}