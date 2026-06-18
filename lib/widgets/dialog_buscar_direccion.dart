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
  // Controladores para capturar el texto escrito
  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  
  // Variables de estado para gestionar la búsqueda
  List<dynamic> sugerencias = []; // Almacena los resultados de la API
  bool estaBuscando = false;      // Controla el estado de carga
  String? error;                 // Muestra mensajes de error si faltan datos
  Timer? temporizador;           // Gestiona el "debounce" para no saturar la API al escribir

  // Valida y guarda el lugar manualmente usando las coordenadas del centro del mapa
  void _guardarLugar() {
    if (nombreController.text.isNotEmpty && direccionController.text.isNotEmpty) {
      final nuevo = Lugar(
        nombre: nombreController.text,
        direccion: direccionController.text, 
        latitud: widget.centroMapa.latitude,
        longitud: widget.centroMapa.longitude,
      );
      widget.onGuardar(nuevo);
      Navigator.pop(context);
    } else {
      setState(() => error = "No seas prisas Pedro, \ntienes que escribir nombre y dirección >:l");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Altura del diálogo al 60% de la pantalla
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return DialogGeneral(
      title: 'Buscar Lugar',
      onSave: _guardarLugar,
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min, // El diálogo se ajusta al contenido
          children: [
            // --- ENTRY NOMBRE LUGAR --- 
            TextField(
              controller: nombreController,
              style: const TextStyle(color: Colors.black), 
              decoration: const InputDecoration(hintText: "Nombre (Ej: Casa Mejor Novia)"),
              inputFormatters: [LengthLimitingTextInputFormatter(19)],
            ),
            const SizedBox(height: 10),
            // --- ENTRY DIRECCIÓN --- 
            TextField(
              controller: direccionController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Dirección (Ej: Avenida Lisboa)",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) {
                // Solo busca si hay al menos 3 letras
                if (texto.length < 3) {
                  setState(() => sugerencias = []);
                  return;
                }
                // Cancela búsquedas previas si el usuario sigue escribiendo para eivtar error
                if (temporizador?.isActive ?? false) temporizador!.cancel();
                temporizador = Timer(const Duration(milliseconds: 800), () async {
                  setState(() => estaBuscando = true);
                  final res = await GeocodingService.buscar(texto);
                  // Actualiza la lista si el widget sigue en pantalla
                  if (mounted) {
                    setState(() {
                      sugerencias = res;
                      estaBuscando = false;
                    });
                  }
                });
              },
            ),
            // --- BARRA DE CARGA ---
            if (estaBuscando)
              const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: Colores.rojo)),
            // --- ERRORES DE VALIDACIÓN ---
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8), 
                child: Text(
                  error!, 
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            // --- LISTA SUGERENCIAS --- 
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sugerencias.length,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sugerencias[index]['display_name'], style: const TextStyle(fontSize: 12)),
                  leading: const Icon(Icons.location_on, color: Colores.rojo),
                  // Al seleccionar una sugerencia, guarda el lugar con las coordenadas encontradas
                  onTap: () {
                    if (nombreController.text.isEmpty) {
                      setState(() => error = "Escribe un nombre primero maldito vago .-.");
                      return;
                    }
                    final nuevo = Lugar(
                      nombre: nombreController.text,
                      direccion: sugerencias[index]['display_name'], 
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