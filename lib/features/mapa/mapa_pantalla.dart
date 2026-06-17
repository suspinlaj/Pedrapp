import 'dart:async'; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:http/http.dart' as http; 
import 'package:pedrapp/core/colores.dart'; 

class Lugar {
  final String nombre;
  final double latitud;
  final double longitud;

  Lugar({required this.nombre, required this.latitud, required this.longitud});

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'latitud': latitud,
    'longitud': longitud,
  };

  factory Lugar.fromJson(Map<String, dynamic> json) => Lugar(
    nombre: json['nombre'],
    latitud: json['latitud'],
    longitud: json['longitud'],
  );
}

class MapaPantalla extends StatefulWidget {
  const MapaPantalla({super.key});

  @override
  State<MapaPantalla> createState() => _MapaPantallaState();
}

class _MapaPantallaState extends State<MapaPantalla> {
  List<Lugar> _misLugares = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _cargarLugaresGuardados(); 
  }

  Future<void> _cargarLugaresGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lugaresString = prefs.getString('lugares_guardados');

    if (lugaresString != null) {
      final List<dynamic> datosDecodificados = jsonDecode(lugaresString);
      setState(() {
        _misLugares = datosDecodificados.map((item) => Lugar.fromJson(item)).toList();
      });
    } else {
      setState(() {
        _misLugares = [
          Lugar(nombre: "Parque de Bomberos Central", latitud: 40.416775, longitud: -3.703790),
        ];
      });
    }
  }

  Future<void> _guardarLugaresEnMemoria() async {
    final prefs = await SharedPreferences.getInstance();
    final String lugaresString = jsonEncode(_misLugares.map((l) => l.toJson()).toList());
    await prefs.setString('lugares_guardados', lugaresString);
  }

  Future<void> _abrirWaze(double lat, double lng) async {
    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(url);
    }
  }

  void _mostrarDialogoEliminar(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('Seguro que quieres borrar "${_misLugares[index].nombre}" de tu mapa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _misLugares.removeAt(index);
              });
              await _guardarLugaresEnMemoria(); 
              
              if (mounted) Navigator.pop(context); 
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarPunto(LatLng puntoClicado) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar este punto exacto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ej: Pista de atletismo"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _misLugares.add(Lugar(
                    nombre: controller.text,
                    latitud: puntoClicado.latitude,
                    longitud: puntoClicado.longitude,
                  ));
                });
                await _guardarLugaresEnMemoria(); 
                Navigator.pop(context);
                Scaffold.of(context).openDrawer();
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colores.rojo)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoBuscarDireccion() {
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    
    List<dynamic> sugerencias = [];
    bool estaBuscando = false;
    Timer? temporizador; 

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Buscar lugar'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(hintText: "Nombre (Ej: Gimnasio)"),
                  ),
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: direccionController,
                    decoration: const InputDecoration(
                      hintText: "Direccion (Ej: Calle Mayor, Madrid)",
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (texto) {
                      if (texto.length < 4) {
                        setStateDialog(() {
                          sugerencias = [];
                        });
                        return;
                      }
                      
                      if (temporizador?.isActive ?? false) temporizador!.cancel();
                      
                      temporizador = Timer(const Duration(milliseconds: 800), () async {
                        // ESCUDO 1: Si la ventana ya esta cerrada, abortamos mision
                        if (!dialogContext.mounted) return;

                        setStateDialog(() => estaBuscando = true);

                        try {
                          final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$texto&format=json&limit=4&countrycodes=es');
                          
                          final response = await http.get(
                            url,
                            headers: {
                              'User-Agent': 'Pedrapp/1.0 (mi_app_de_bomberos@gmail.com)'
                            }
                          );
                          
                          // ESCUDO 2: Comprobamos despues de la descarga por si acaso
                          if (!dialogContext.mounted) return;

                          if (response.statusCode == 200) {
                            setStateDialog(() {
                              sugerencias = jsonDecode(response.body);
                              estaBuscando = false;
                            });
                          } else {
                            setStateDialog(() => estaBuscando = false);
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setStateDialog(() => estaBuscando = false);
                        }
                      });
                    },
                  ),
                  
                  if (estaBuscando) 
                    const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: LinearProgressIndicator(color: Colores.rojo),
                    ),

                  const SizedBox(height: 10),

                  if (sugerencias.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sugerencias.length,
                        itemBuilder: (context, index) {
                          final res = sugerencias[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(res['display_name'], style: const TextStyle(fontSize: 12)),
                            leading: const Icon(Icons.location_on, color: Colores.rojo, size: 20),
                            onTap: () async {
                              if (nombreController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ponle un nombre primero!'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              temporizador?.cancel(); // Apagamos el reloj antes de cerrar

                              setState(() {
                                _misLugares.add(Lugar(
                                  nombre: nombreController.text,
                                  latitud: double.parse(res['lat']),
                                  longitud: double.parse(res['lon']),
                                ));
                              });
                              await _guardarLugaresEnMemoria();

                              if (mounted) {
                                Navigator.pop(dialogContext); 
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lugar guardado!'), backgroundColor: Colors.green),
                                );
                                _mapController.move(
                                  LatLng(double.parse(res['lat']), double.parse(res['lon'])), 
                                  15.0 
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  temporizador?.cancel(); // DESTRUIMOS EL RELOJ AL CANCELAR
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  if (nombreController.text.isNotEmpty) {
                    temporizador?.cancel(); // DESTRUIMOS EL RELOJ AL GUARDAR MANUALMENTE

                    final centroActual = _mapController.camera.center;

                    setState(() {
                      _misLugares.add(Lugar(
                        nombre: nombreController.text,
                        latitud: centroActual.latitude,
                        longitud: centroActual.longitude,
                      ));
                    });
                    await _guardarLugaresEnMemoria();

                    if (mounted) {
                      Navigator.pop(dialogContext); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lugar guardado manualmente!'), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ponle un nombre primero!'), backgroundColor: Colors.orange),
                      );
                    }
                  }
                },
                child: const Text('Guardar manual', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lugares', style: TextStyle(fontFamily: 'Titulo', fontSize: 24)),
        backgroundColor: Colores.rojo,
        foregroundColor: Colors.white,
      ),
      
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colores.rojo),
              child: Center(
                child: Text(
                  'PUNTOS CLAVE',
                  style: TextStyle(color: Colors.white, fontFamily: 'Titulo', fontSize: 28),
                ),
              ),
            ),
            Expanded(
              child: _misLugares.isEmpty
                  ? const Center(child: Text('Anade tu primer lugar'))
                  : ListView.builder(
                      itemCount: _misLugares.length,
                      itemBuilder: (context, index) {
                        final lugar = _misLugares[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colores.rojo),
                          title: Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              IconButton(
                                icon: const Icon(Icons.navigation, color: Colores.gris),
                                onPressed: () {
                                  Navigator.pop(context); 
                                  _abrirWaze(lugar.latitud, lugar.longitud);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _mostrarDialogoEliminar(index),
                              ),
                            ],
                          ),
                          
                          onTap: () {
                            Navigator.pop(context);
                            _mapController.move(LatLng(lugar.latitud, lugar.longitud), 15.0);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colores.rojo,
        foregroundColor: Colors.white,
        onPressed: () => _mostrarDialogoBuscarDireccion(),
        child: const Icon(Icons.add, size: 30),
      ),

      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(40.416775, -3.703790), 
          initialZoom: 12.0,
          onLongPress: (tapPosition, point) => _mostrarDialogoAgregarPunto(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: _misLugares.map((lugar) {
              return Marker(
                point: LatLng(lugar.latitud, lugar.longitud),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _abrirWaze(lugar.latitud, lugar.longitud),
                  child: const Icon(
                    Icons.location_on,
                    color: Colores.rojo, 
                    size: 45,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}