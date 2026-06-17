import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/servicios/geocoding_service.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogBuscarDireccion extends StatefulWidget {
  final LatLng centroMapa;
  final Function(Lugar) onGuardar;

  const DialogBuscarDireccion({super.key, required this.centroMapa, required this.onGuardar});

  @override
  State<DialogBuscarDireccion> createState() => _DialogBuscarDireccionState();
}

class _DialogBuscarDireccionState extends State<DialogBuscarDireccion> {
  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  List<dynamic> sugerencias = [];
  bool estaBuscando = false;
  String? error;
  Timer? temporizador;

  void _guardarLugar() {
    if (nombreController.text.isNotEmpty && direccionController.text.isNotEmpty) {
      final nuevo = Lugar(
        nombre: nombreController.text,
        latitud: widget.centroMapa.latitude,
        longitud: widget.centroMapa.longitude,
      );
      widget.onGuardar(nuevo);
      Navigator.pop(context);
    } else {
      setState(() => error = "Tienes que escribir nombre y dirección");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: 'Buscar lugar',
      onSave: _guardarLugar,
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              // Solo añadimos el color, nada más
              style: const TextStyle(color: Colors.black), 
              decoration: const InputDecoration(hintText: "Nombre (Ej: Gimnasio)"),
              inputFormatters: [LengthLimitingTextInputFormatter(19)],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: direccionController,
              // Solo añadimos el color, nada más
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Dirección (Ej: Calle Mayor)",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) {
                if (texto.length < 4) {
                  setState(() => sugerencias = []);
                  return;
                }
                if (temporizador?.isActive ?? false) temporizador!.cancel();
                temporizador = Timer(const Duration(milliseconds: 800), () async {
                  setState(() => estaBuscando = true);
                  final res = await GeocodingService.buscar(texto);
                  if (mounted) {
                    setState(() {
                      sugerencias = res;
                      estaBuscando = false;
                    });
                  }
                });
              },
            ),
            if (estaBuscando)
              const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: Colores.rojo)),
            if (error != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sugerencias.length,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sugerencias[index]['display_name'], style: const TextStyle(fontSize: 12)),
                  leading: const Icon(Icons.location_on, color: Colores.rojo),
                  onTap: () {
                    if (nombreController.text.isEmpty) {
                      setState(() => error = "Escribe un nombre primero");
                      return;
                    }
                    final nuevo = Lugar(
                      nombre: nombreController.text,
                      latitud: double.parse(sugerencias[index]['lat']),
                      longitud: double.parse(sugerencias[index]['lon']),
                    );
                    widget.onGuardar(nuevo);
                    Navigator.pop(context);
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}