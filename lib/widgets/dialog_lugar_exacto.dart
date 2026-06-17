import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogLugarExacto extends StatefulWidget {
  final LatLng punto;
  final Function(Lugar) onGuardar;

  const DialogLugarExacto({super.key, required this.punto, required this.onGuardar});

  @override
  State<DialogLugarExacto> createState() => _DialogLugarExactoState();
}

class _DialogLugarExactoState extends State<DialogLugarExacto> {
  final controller = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: 'Guardar este punto',
      onSave: () {
        if (controller.text.isNotEmpty) {
          widget.onGuardar(Lugar(nombre: controller.text, latitud: widget.punto.latitude, longitud: widget.punto.longitude));
          Navigator.pop(context);
        } else {
          setState(() => error = "Ponle un nombre!");
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            // Aquí he añadido el color negro que pediste
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(hintText: "Ej: Pista de atletismo"),
            autofocus: true,
            inputFormatters: [LengthLimitingTextInputFormatter(19)],
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }
}