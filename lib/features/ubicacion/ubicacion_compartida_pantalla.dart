import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedrapp/widgets/ubicacion/dialog_identidad.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/servicios/ubicacion_service.dart';
import 'package:pedrapp/widgets/ubicacion/marcador_ubicacion.dart'; 
import 'package:pedrapp/widgets/ubicacion/tarjeta_historial.dart';   

class UbicacionCompartidaPantalla extends StatefulWidget {
  const UbicacionCompartidaPantalla({super.key});

  @override
  State<UbicacionCompartidaPantalla> createState() => _UbicacionCompartidaPantallaState();
}

class _UbicacionCompartidaPantallaState extends State<UbicacionCompartidaPantalla> {
  final MapController _mapController = MapController();
  final UbicacionService _ubicacionService = UbicacionService();
  
  String miId = "Susana"; 
  bool compartiendo = false;
  
  // Bandera para controlar que el mapa solo se encuadre la primera vez al abrir
  bool _primerEncuadreRealizado = false;

  @override
  void initState() {
    super.initState();
    _cargarIdentidad(); 
  }

  void _cargarIdentidad() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      miId = prefs.getString('quien_soy') ?? "Susana";
    });
  }

  // --- MODIFICADO: Ahora abre tu nuevo componente DialogIdentidad estilizado ---
  void _mostrarDialogoIdentidad() {
    showDialog(
      context: context,
      builder: (context) => DialogIdentidad(
        identidadActual: miId,
        onSave: (nuevaIdentidad) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('quien_soy', nuevaIdentidad); // Guarda la selección en memoria
          setState(() {
            miId = nuevaIdentidad;
            _primerEncuadreRealizado = false; // Reiniciamos para que busque al otro usuario
          });
        },
      ),
    );
  }

  void _toggleCompartir() async {
    if (compartiendo) {
      // --- MODIFICADO: Le pasamos el miId para marcar inactivo en Firebase ---
      _ubicacionService.detenerSeguimiento(miId);
      setState(() => compartiendo = false);
    } else {
      try {
        await _ubicacionService.iniciarSeguimiento(miId);
        setState(() => compartiendo = true);
        
        Position posicionActual = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        _mapController.move(LatLng(posicionActual.latitude, posicionActual.longitude), 15.0);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Función auxiliar para formatear la última conexión en texto legible
  String _calcularTiempoTranscurrido(Timestamp? timestamp) {
    if (timestamp == null) return "Sin datos de conexión";
    
    final DateTime horaFirebase = timestamp.toDate();
    final DateTime ahora = DateTime.now();
    final Duration diferencia = ahora.difference(horaFirebase);
    
    final String horaStr = "${horaFirebase.hour.toString().padLeft(2, '0')}:${horaFirebase.minute.toString().padLeft(2, '0')}";

    if (diferencia.inMinutes < 1) {
      return "En directo ($horaStr)";
    } else if (diferencia.inMinutes < 60) {
      return "Hace ${diferencia.inMinutes} min ($horaStr)";
    } else if (diferencia.inDays < 1) {
      return "Hace ${diferencia.inHours} horas ($horaStr)";
    } else {
      return "${horaFirebase.day}/${horaFirebase.month} a las $horaStr";
    }
  }

  @override
  void dispose() {
    // --- MODIFICADO: Le pasamos el miId al apagar al salir de la pantalla ---
    _ubicacionService.detenerSeguimiento(miId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: "Elegir quién soy",
            onPressed: () {
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

      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ubicaciones_seguridad').snapshots(),
            builder: (context, snapshot) {
              
              List<Marker> marcadoresEnDirecto = [];
              LatLng? posicionPareja;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var datos = doc.data() as Map<String, dynamic>;
                  double? lat = datos['latitud'];
                  double? lng = datos['longitud'];
                  
                  if (lat != null && lng != null) {
                    bool soyYo = doc.id == miId;

                    if (!soyYo) {
                      posicionPareja = LatLng(lat, lng);
                    }

                    marcadoresEnDirecto.add(
                      Marker(
                        point: LatLng(lat, lng),
                        width: 100, 
                        height: 80,  
                        // En flutter_map se usa topCenter para forzar a la caja a desplazarse 
                        // hacia arriba y que su base toque la coordenada de verdad.
                        alignment: Alignment.topCenter, 
                        child: MarcadorUbicacion(
                          nombre: doc.id,
                          soyYo: soyYo,
                          colorTema: soyYo ? Colores.amarillo : Colores.rojo,
                        ),
                      )
                    );
                  }
                }

                // Auto-encuadre inicial hacia la pareja
                if (posicionPareja != null && !_primerEncuadreRealizado) {
                  _primerEncuadreRealizado = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.move(posicionPareja!, 14.5);
                  });
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(40.416775, -3.703790), 
                  initialZoom: 12.0,
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
          
          // --- TARJETAS SUPERIORES (CHIVATOS DE ESTADO) ---
          Positioned(
            top: 10,
            left: 10,
            right: 10, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                
                // Invocamos a la tarjeta del historial aislada (que ahora dibuja el bocadillo dinámico abajo)
                TarjetaHistorial(
                  miId: miId,
                  calcularTiempoFn: _calcularTiempoTranscurrido,
                ),
              ],
            ),
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleCompartir,
        backgroundColor: compartiendo ? Colores.amarillo : Colores.rojo,
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