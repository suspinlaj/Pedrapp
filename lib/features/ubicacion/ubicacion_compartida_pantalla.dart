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
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/servicios/lugar_service.dart';

class UbicacionCompartidaPantalla extends StatefulWidget {
  const UbicacionCompartidaPantalla({super.key});

  @override
  State<UbicacionCompartidaPantalla> createState() => _UbicacionCompartidaPantallaState();
}

class _UbicacionCompartidaPantallaState extends State<UbicacionCompartidaPantalla> {
  
  // CONTROLADORES Y VARIABLES DE ESTADO
  
  final MapController _mapController = MapController(); // Permite mover la cámara y el zoom por código
  final UbicacionService _ubicacionService = UbicacionService(); // Instancia del servicio que gestiona el GPS nativo
  
  String miId = "Susana"; // Identificador del usuario actual (se sobreescribe con la memoria)
  bool compartiendo = false; // Estado del botón -> true si el GPS está encendido transmitiendo, false si está apagado
  
  // Evita que el mapa encuadre al otro todo el tiempo
  bool _primerEncuadreRealizado = false;

  // guardar conexión en vivo para no abrir y cerrar  conexciones todo e rato
  late final Stream<QuerySnapshot> _ubicacionesStream;

  List<Marker> _marcadoresLugaresGris = []; // lugares guardados

  @override
  void initState() {
    super.initState();
    _cargarIdentidad(); // leer disco duro para saber quién es
    _cargarLugaresInformativos(); //  Recuperar los lugares  para pintarlos en mapa
    _ubicacionesStream = FirebaseFirestore.instance.collection('ubicaciones_seguridad').snapshots();
  }

  @override
  void dispose() {
    // apaga el GPS para bateria movil
    _ubicacionService.detenerSeguimiento(miId);
    super.dispose();
  }

  // Cargar la identidad guardada 
  void _cargarIdentidad() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      miId = prefs.getString('quien_soy') ?? "Susana";
    });
  }

  //  Generar  pines lugares
  Future<void> _cargarLugaresInformativos() async {
    try {
      final List<Lugar> lugares = await LugarService.obtener();
      setState(() {
        _marcadoresLugaresGris = lugares.map((l) => Marker(
          point: LatLng(l.latitud, l.longitud),
          width: 70, 
          height: 55, 
          alignment: Alignment.topCenter,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Etiqueta del lugar
              Positioned(
                bottom: 26,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colores.gris.withAlpha(150), width: 1.5),
                  ),
                  child: Text(
                    l.nombre,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colores.gris,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Pin pequeño de ubicación en gris informativo (tamaño 28 frente al 45 original)
              Icon(
                Icons.location_on,
                color: Colores.gris.withAlpha(150),
                size: 28,
              ),
            ],
          ),
        )).toList();
      });
    } catch (e) {
      debugPrint("Error cargando pines informativos: $e");
    }
  }

  // diálogo  para cambiar usuario 
  void _mostrarDialogoIdentidad() {
    showDialog(
      context: context,
      builder: (context) => DialogIdentidad(
        identidadActual: miId,
        onSave: (nuevaIdentidad) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('quien_soy', nuevaIdentidad); // Guarda la nueva selección en memoria permanente
          setState(() {
            miId = nuevaIdentidad;
            _primerEncuadreRealizado = false; // Resetea el encuadre para buscar la ubicación de la nueva persona
          });
        },
      ),
    );
  }

  // Enciende el rastreador en vivo o lo apaga avisando a Firebase
  void _toggleCompartir() async {
    if (compartiendo) {
      _ubicacionService.detenerSeguimiento(miId); // Detiene el flujo del GPS y pone 'activo: false' en Firebase
      setState(() => compartiendo = false);
    } else {
      try {
        await _ubicacionService.iniciarSeguimiento(miId); // Pide permisos, activa el servicio en segundo plano y pone 'activo: true'
        setState(() => compartiendo = true);
        
        // mueve camara del mapa a posición actual
        Position posicionActual = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        _mapController.move(LatLng(posicionActual.latitude, posicionActual.longitude), 15.0);
        
      } catch (e) {
        // barra inferior error en caso de que falten permisos o el GPS esté apagado
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Transforma el timestamp del servidor de Firebase en un formato entendible 
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
          // TITULO
          child: Text(
            'Seguridad',
            style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
          ),
        ),
        backgroundColor: Colores.rojo,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
        actions: [
          // Botón del muñequito para acceder al selector de identidad
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

      // --- CUERPO PRINCIPAL ---
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(40.416775, -3.703790), // Madrid por defecto si no hay datos 
              initialZoom: 12.0,
              // Bloquear que se peuda girar el mapa
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),

              // --- CAPA INFO GRIS ---
              // Pintamos primero la lista fija de tus lugares en gris de fondo
              MarkerLayer(markers: _marcadoresLugaresGris),
              
              // FONDO -> escucha en tiempo real de FirebaseFirestore
              StreamBuilder<QuerySnapshot>(
                stream: _ubicacionesStream, 
                builder: (context, snapshot) {
                  
                  List<Marker> marcadoresEnDirecto = [];
                  LatLng? posicionPareja;

                  if (snapshot.hasData) {
                    // Bucle que lee las ubicaciones disponibles en la base de datos
                    for (var doc in snapshot.data!.docs) {
                      var datos = doc.data() as Map<String, dynamic>;
                      double? lat = datos['latitud'];
                      double? lng = datos['longitud'];
                      
                      if (lat != null && lng != null) {
                        bool soyYo = doc.id == miId;

                        if (!soyYo) {
                          posicionPareja = LatLng(lat, lng); // Identifica las coordenadas del otro para el auto-zoom
                        }

                        // Añade una chincheta a la lista del mapa
                        marcadoresEnDirecto.add(
                          Marker(
                            point: LatLng(lat, lng),
                            width: 100, 
                            height: 80,  
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

                    // auto-encuadre inicial hacia la otra persona al abrir la pantalla
                    if (posicionPareja != null && !_primerEncuadreRealizado) {
                      _primerEncuadreRealizado = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mapController.move(posicionPareja!, 13.0); // zoom mapa
                      });
                    }
                  }

                  return MarkerLayer(markers: marcadoresEnDirecto); // Dibujar capa marcadores en vivo por encima de la gris
                },
              ),
            ],
          ),
          
          // BOCADDILLITOS DE HISTORIAL Y AVISO DE DESCONEXIÓN
          Positioned(
            top: 10,
            left: 10,
            right: 10, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                
                TarjetaHistorial(
                  miId: miId,
                  calcularTiempoFn: _calcularTiempoTranscurrido,
                ),
              ],
            ),
          )
        ],
      ),
      
      // --- BOTÓN PONER UBICACION ---
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