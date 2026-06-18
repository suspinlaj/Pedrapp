import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogLugarExacto extends StatefulWidget {
  final LatLng punto; // Coordenadas del punto seleccionado
  final Function(Lugar) onGuardar; // Callback para devolver el lugar creado

  const DialogLugarExacto({super.key, required this.punto, required this.onGuardar});

  @override
  State<DialogLugarExacto> createState() => _DialogLugarExactoState();
}

class _DialogLugarExactoState extends State<DialogLugarExacto> {
  final controller = TextEditingController(); // Controla la entrada de texto
  String? error; 

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      // --- TIUTLO ---
      title: 'Guardar este lugar',
      onSave: () {
        // Valida que no esté vacío antes de crear el objeto Lugar
        if (controller.text.isNotEmpty) {
          widget.onGuardar(Lugar(
            nombre: controller.text, 
            direccion: 'Punto seleccionado', 
            latitud: widget.punto.latitude, 
            longitud: widget.punto.longitude,
          ));          Navigator.pop(context); // Cierra el diálogo tras guardar
        } else {
          setState(() => error = "¿Y si escribes un nombre primero qué tal?"); // Muestra aviso si está vacío
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black), // Texto visible
            decoration: const InputDecoration(hintText: "Ej: Mi casita uwu"),
            autofocus: true, // Abre el teclado automáticamente
            inputFormatters: [LengthLimitingTextInputFormatter(19)], // Limita a 19 caracteres
          ),
          // Muestra mensaje de error debajo del campo si existe
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }
}