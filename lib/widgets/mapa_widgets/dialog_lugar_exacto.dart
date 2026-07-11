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
  final nombreController = TextEditingController(); // Controla la entrada de texto del nombre
  final direccionController = TextEditingController(); // Controla la entrada de la dirección
  String? error; 

  @override
  void dispose() {
    nombreController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      // --- TIUTLO ---
      title: 'Guardar Lugar',
      onSave: () {
        // Valida que no esté vacío antes de crear el objeto Lugar
        if (nombreController.text.isNotEmpty) {
          widget.onGuardar(Lugar(
            nombre: nombreController.text, 
            // Coge lo que escriba en dirección. Si lo deja vacío, pone un texto por defecto 
            direccion: direccionController.text.isNotEmpty ? direccionController.text : 'Punto en el mapa', 
            latitud: widget.punto.latitude, 
            longitud: widget.punto.longitude,
          ));          
          Navigator.pop(context); // Cierra el diálogo tras guardar
        } else {
          setState(() => error = "¿Y si escribes un nombre primero qué tal?"); // Muestra aviso si está vacío
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- CAMPO NOMBRE ---
          TextField(
            controller: nombreController,
            style: const TextStyle(color: Colors.black), // Texto visible
            decoration: const InputDecoration(hintText: "Ej: Mi casita uwu"),
            autofocus: true, // Abre el teclado automáticamente
            inputFormatters: [LengthLimitingTextInputFormatter(19)], // Limita a 19 caracteres
          ),
          const SizedBox(height: 10),
          // --- CAMPO DIRECCIÓN  ---
          TextField(
            controller: direccionController,
            style: const TextStyle(color: Colors.black), 
            decoration: const InputDecoration(hintText: "Dirección (Opcional)"),
          ),
          // Muestra mensaje de error debajo del campo si existe
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }
}