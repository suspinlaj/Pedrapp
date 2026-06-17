import 'dart:async'; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  bool _mostrarLista = false;

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
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String? error;
          return AlertDialog(
            title: const Text('Guardar este punto exacto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Ej: Pista de atletismo"),
                  autofocus: true,
                  inputFormatters: [LengthLimitingTextInputFormatter(19)],
                )
              ],
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
                      _mostrarLista = true; 
                    });
                    await _guardarLugaresEnMemoria(); 
                    Navigator.pop(context);
                  } else {
                    setStateDialog(() => error = "Ponle un nombre!");
                  }
                },
                child: const Text('Guardar', style: TextStyle(color: Colores.rojo)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _mostrarDialogoBuscarDireccion() {
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    
    List<dynamic> sugerencias = [];
    bool estaBuscando = false;
    String? error;
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
                    inputFormatters: [LengthLimitingTextInputFormatter(19)],
                  ),
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: direccionController,
                    decoration: const InputDecoration(
                      hintText: "Direccion (Ej: Calle Mayor)",
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
                        if (!dialogContext.mounted) return;

                        setStateDialog(() => estaBuscando = true);

                        try {
                          final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$texto&format=json&limit=4&countrycodes=es');
                          
                          final response = await http.get(
                            url,
                            headers: {
                              'User-Agent': 'Pedrapp/1.0 (tu_email@ejemplo.com)'
                            }
                          );
                          
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

                  if (error != null) ...[
                     const SizedBox(height: 10),
                     Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],

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
                                setStateDialog(() => error = "Escribe un nombre primero");
                                return;
                              }

                              temporizador?.cancel();

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
                  temporizador?.cancel(); 
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  if (nombreController.text.isNotEmpty && direccionController.text.isNotEmpty) {
                    temporizador?.cancel(); 

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
                    }
                  } else {
                    setStateDialog(() => error = "Tienes que escribir nombre y direccion");
                  }
                },
                child: const Text('Guardar', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paddingAbajo = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa', style: TextStyle(fontFamily: 'Titulo', fontSize: 24)),
        backgroundColor: Colores.rojo,
        foregroundColor: Colors.white,
      ),
      
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn_anadir', 
        backgroundColor: Colores.rojo,
        foregroundColor: Colors.white,
        onPressed: () => _mostrarDialogoBuscarDireccion(),
        child: const Icon(Icons.add, size: 30),
      ),

      body: Stack(
        children: [
          
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.416775, -3.703790), 
              initialZoom: 12.0,
              onLongPress: (tapPosition, point) => _mostrarDialogoAgregarPunto(point),
            ),
            children: [
              // --- MAPA A COLOR USANDO CARTODB VOYAGER ---
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              // -------------------------------------------
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

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _mostrarLista ? 0 : -300,
            top: 0,
            bottom: 0,
            width: 280, 
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9), 
                border: const Border(
                  right: BorderSide(
                    color: Colores.rojo, 
                    width: 3.0, 
                  ),
                ),
                boxShadow: [
                  if (_mostrarLista)
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 5.0),
                      child: Text(
                        'Lugares Guardados',
                        style: TextStyle(
                          color: Colores.rojo,
                          fontFamily: 'Titulo', 
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colores.gris, thickness: 2.0),
                    Expanded(
                      child: _misLugares.isEmpty
                          ? const Center(child: Text('Anade tu primer lugar'))
                          : ListView.separated(
                              itemCount: _misLugares.length,
                              separatorBuilder: (context, index) {
                                return Divider(
                                  color: Colores.rojo, 
                                  indent: 40.0, 
                                  endIndent: 40.0, 
                                  height: 1.0,
                                  thickness: 1.5,
                                );
                              },
                              itemBuilder: (context, index) {
                                final lugar = _misLugares[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() => _mostrarLista = false); 
                                    _mapController.move(LatLng(lugar.latitud, lugar.longitud), 15.0);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colores.rojo, size: 24),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            lugar.nombre, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() => _mostrarLista = false); 
                                                _abrirWaze(lugar.latitud, lugar.longitud);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Icon(Icons.navigation, color: Colores.gris, size: 22),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _mostrarDialogoEliminar(index),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Icon(Icons.delete, color: Colors.red, size: 22),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: paddingAbajo + 16, 
            child: FloatingActionButton(
              heroTag: 'btn_lista',
              backgroundColor: Colores.rojo,
              foregroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  _mostrarLista = !_mostrarLista; 
                });
              },
              child: Icon(_mostrarLista ? Icons.close : Icons.list, size: 30),
            ),
          ),

        ],
      ),
    );
  }
}