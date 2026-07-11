import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/widgets/dialog_general.dart';
import 'package:pedrapp/widgets/marcas_widgets/tiempo_dialog.dart';

// Diálogo para crear una prueba personalizada desde cero
class DialogoNuevaCategoria extends StatefulWidget {
  final Color colorFondo;
  final Function(CategoriaMarca) onSave;

  const DialogoNuevaCategoria({
    super.key, 
    required this.colorFondo, 
    required this.onSave
  });

  @override
  State<DialogoNuevaCategoria> createState() => _DialogoNuevaCategoriaState();
}

class _DialogoNuevaCategoriaState extends State<DialogoNuevaCategoria> {
  // Controladores para el nombre de la prueba y el objetivo inicial
  final nombreController = TextEditingController();
  final minsController = TextEditingController();
  final secsController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    minsController.dispose();
    secsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: "Nueva PrueBa",
      saveText: "Crear",
      colorTema: widget.colorFondo,
      onSave: () {
        // Validar que el usuario haya escrito un nombre
        if (nombreController.text.trim().isEmpty) return;

        // Extraer el tiempo objetivo en segundos
        double mins = double.tryParse(minsController.text) ?? 0.0;
        double secs = double.tryParse(secsController.text) ?? 0.0;
        double totalSegundos = (mins * 60) + secs;

        // Validar que el tiempo objetivo sea mayor a 0
        if (totalSegundos > 0) {
          // Construir la nueva categoría
          final nuevaCategoria = CategoriaMarca(
            id: "custom_${DateTime.now().millisecondsSinceEpoch}", // ID único basado en la hora
            nombre: nombreController.text.trim(), // Limpia espacios al principio/final
            icono: Icons.star, // Icono temporal
            objetivo: totalSegundos,
          );
          
          widget.onSave(nuevaCategoria);
          Navigator.pop(context);
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo para escribir el nombre de la prueba
          TextField(
            controller: nombreController,
            textCapitalization: TextCapitalization.sentences, // Empieza con mayúscula
            decoration: InputDecoration(
              labelText: "Nombre de la prueba",
              labelStyle: const TextStyle(fontSize: 14),
              floatingLabelStyle: TextStyle(color: widget.colorFondo, fontWeight: FontWeight.bold),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Objetivo inicial:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Fila con los campos de tiempo
          Row(
            children: [
              TiempoDialog(label: "Minutos", controller: minsController, colorFondo: widget.colorFondo),
              const SizedBox(width: 10),
              const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              TiempoDialog(label: "Segundos", controller: secsController, colorFondo: widget.colorFondo, isDecimal: true),
            ],
          ),
        ],
      ),
    );
  }
}