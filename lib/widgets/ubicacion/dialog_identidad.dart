import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/widgets/dialog_general.dart';


class DialogIdentidad extends StatefulWidget {
  final String identidadActual; // Recibe el id que está actualmente guardado (Pedro o Susana)
  final Function(String) onSave; // Devuelve el nuevo nombre seleccionado al guardar

  const DialogIdentidad({
    super.key,
    required this.identidadActual,
    required this.onSave,
  });

  @override
  State<DialogIdentidad> createState() => _DialogIdentidadState();
}

class _DialogIdentidadState extends State<DialogIdentidad> {
  late String _seleccionada;

  @override
  void initState() {
    super.initState();
    // Inicializa la selección con el valor que ya tenía el usuario
    _seleccionada = widget.identidadActual;
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: "quien ERES?", // Título adaptado al estilo general
      saveText: "Aceptar",
      colorTema: Colores.rojo,
      // Acción al presionar el botón de guardar
      onSave: () {
        widget.onSave(_seleccionada);
        Navigator.pop(context);
      },
      // Contenido dinámico adaptado al selector de personas
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Elige quién usa este móvil para compartir su ubicación con el otro.",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          // Opción Susana
          RadioListTile<String>(
            title: const Text("Soy Susana", style: TextStyle(fontWeight: FontWeight.bold)),
            value: "Susana",
            groupValue: _seleccionada,
            activeColor: Colores.rojo,
            onChanged: (value) {
              if (value != null) setState(() => _seleccionada = value);
            },
          ),
          // Opción Pedro
          RadioListTile<String>(
            title: const Text("Soy Pedro", style: TextStyle(fontWeight: FontWeight.bold)),
            value: "Pedro",
            groupValue: _seleccionada,
            activeColor: Colores.rojo,
            onChanged: (value) {
              if (value != null) setState(() => _seleccionada = value);
            },
          ),
        ],
      ),
    );
  }
}