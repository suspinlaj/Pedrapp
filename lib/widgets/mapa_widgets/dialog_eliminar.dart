import 'package:flutter/material.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogEliminar extends StatelessWidget {
  final String titulo; // Ej: 'Eliminar Lugar' o 'Eliminar Marca'
  final String nombreItem; // Lo que irá en negrita (el lugar o la categoría)
  final String finalMensaje; // Lo que va al final (Ej: 'de tu mapa?' o '?\n\nEsto no se puede deshacer.')
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
      title: titulo,
      saveText: 'Eliminar',
      onSave: onConfirm,
      content: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 18, color: Colors.black87),
          children: [
            const TextSpan(text: '¿Seguro que quieres borrar "'),
            TextSpan(
              text: nombreItem, 
              style: const TextStyle(fontWeight: FontWeight.bold), 
            ),
            TextSpan(text: '" $finalMensaje'), // Añadimos el texto final dinámico
          ],
        ),
        textAlign: TextAlign.start, 
      ),
    );
  }
}