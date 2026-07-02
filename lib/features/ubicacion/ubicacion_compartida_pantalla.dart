import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVA IMPORTACIÓN PARA LA MEMORIA
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/servicios/ubicacion_service.dart';

class UbicacionCompartidaPantalla extends StatefulWidget {
  const UbicacionCompartidaPantalla({super.key});

  @override
  State<UbicacionCompartidaPantalla> createState() => _UbicacionCompartidaPantallaState();
}

class _UbicacionCompartidaPantallaState extends State<UbicacionCompartidaPantalla> {
  final MapController _mapController = MapController();
  final UbicacionService _ubicacionService = UbicacionService();
  
  // Ahora miId cambia dinámicamente. Por defecto es Susana, pero la memoria lo cambiará.
  String miId = "Susana"; 

  bool compartiendo = false;

  @override
  void initState() {
    super.initState();
    _cargarIdentidad(); // Al abrir la pantalla, lee la memoria del móvil
  }

  // --- MAGIA DE LA MEMORIA ---
  // Lee quién usó este móvil la última vez
  void _cargarIdentidad() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      miId = prefs.getString('quien_soy') ?? "Susana";
    });
  }

  // Diálogo para elegir quién eres sin tener que sacar 2 APKs
  void _mostrarDialogoIdentidad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Quién usa este móvil?", style: TextStyle(fontFamily: 'Titulo', color: Colores.rojo)),
        content: const Text("Elige quién eres para que vuestra chincheta no se pise en el mapa."),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('quien_soy', "Susana"); // Guarda Susana en memoria
              setState(() => miId = "Susana");
              Navigator.pop(context);
            },
            child: const Text("Soy Susana", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('quien_soy', "Pedro"); // Guarda Pedro en memoria
              setState(() => miId = "Pedro");
              Navigator.pop(context);
            },
            child: const Text("Soy Pedro", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Botón para encender/apagar tu propio GPS
  void _toggleCompartir() async {
    if (compartiendo) {
      _ubicacionService.detenerSeguimiento();
      setState(() => compartiendo = false);
    } else {
      try {
        await _ubicacionService.iniciarSeguimiento(miId);
        setState(() => compartiendo = true);
        
        // Forzamos al GPS a darnos la posición EXACTA AHORA MISMO y movemos la cámara hacia ti
        Position posicionActual = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        _mapController.move(LatLng(posicionActual.latitude, posicionActual.longitude), 15.0);
        
      } catch (e) {
        // Muestra error si no da permisos
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    // Al salir de la pantalla, si quieres que deje de rastrear, lo apagas aquí. 
    _ubicacionService.detenerSeguimiento();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- BARRA SUPERIOR ---
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'Seguridad',
            style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
          ),
        ),
        backgroundColor: Colores.rojo,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
        actions: [
          // --- BOTÓN NUEVO PARA ELEGIR IDENTIDAD ---
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: "Elegir quién soy",
            onPressed: () {
              // Si estás compartiendo, no te deja cambiar de identidad para no liar a Firebase
              if (compartiendo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Apaga el GPS primero para cambiar de usuario."))
                );
              } else {
                _mostrarDialogoIdentidad();
              }
            },
          ),
        ],
      ),

      // --- CUERPO PRINCIPAL ---
      body: Stack(
        children: [
          // StreamBuilder escucha la base de datos en tiempo real
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ubicaciones_seguridad').snapshots(),
            builder: (context, snapshot) {
              
              List<Marker> marcadoresEnDirecto = [];

              if (snapshot.hasData) {
                // Recorre todos los documentos (el tuyo y el de tu pareja)
                for (var doc in snapshot.data!.docs) {
                  var datos = doc.data() as Map<String, dynamic>;
                  double? lat = datos['latitud'];
                  double? lng = datos['longitud'];
                  
                  if (lat != null && lng != null) {
                    // Si el documento es el tuyo, pinta chincheta verde. Si no, azul.
                    bool soyYo = doc.id == miId;

                    marcadoresEnDirecto.add(
                      Marker(
                        point: LatLng(lat, lng),
                        width: 150,
                        height: 100,
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 35,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: soyYo ? Colors.green : Colors.blue, width: 2),
                                ),
                                child: Text(
                                  soyYo ? "Yo" : doc.id, 
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 5),
                              child: Icon(
                                Icons.location_on, 
                                color: soyYo ? Colors.green : Colors.blue, 
                                size: 45
                              ),
                            )
                          ],
                        ),
                      )
                    );
                  }
                }
              }

              // Pinta el mapa con los marcadores que haya encontrado en Firebase
              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(40.416775, -3.703790), // Madrid por defecto
                  initialZoom: 12.0,
                  // Bloqueamos la rotación del mapa
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  MarkerLayer(markers: marcadoresEnDirecto),
                ],
              );
            },
          ),
          
          // --- CHIVATO VISUAL DE IDENTIDAD (OPCIONAL) ---
          // Una tarjetita arriba que te recuerda quién tiene puesto el móvil
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colores.gris, width: 2)
              ),
              child: Text("Móvil de: $miId", style: const TextStyle(fontWeight: FontWeight.bold, color: Colores.rojo)),
            ),
          )
        ],
      ),
      
      // --- BOTÓN PARA COMPARTIR UBICACIÓN ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleCompartir,
        backgroundColor: compartiendo ? Colors.green : Colores.rojo,
        icon: Icon(compartiendo ? Icons.gps_fixed : Icons.gps_off, color: Colors.white),
        label: Text(
          compartiendo ? "Compartiendo..." : "Compartir mi ubicación", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colores.gris, width: 3),
        ),
      ),
    );
  }
}