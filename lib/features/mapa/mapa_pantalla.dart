import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/servicios/lugar_service.dart';
import 'package:pedrapp/widgets/dialog_eliminar.dart';
import 'package:pedrapp/widgets/lista_lugares.dart';
import 'package:pedrapp/widgets/dialog_lugar_exacto.dart';
import 'package:pedrapp/widgets/dialog_buscar_direccion.dart';
import 'package:url_launcher/url_launcher.dart';

class MapaPantalla extends StatefulWidget {
  const MapaPantalla({super.key});

  @override
  State<MapaPantalla> createState() => _MapaPantallaState();
}

class _MapaPantallaState extends State<MapaPantalla> {
  List<Lugar> _misLugares = []; // Lista de lugares guardados
  final MapController _mapController = MapController(); // Controlar el zoom y movimiento del mapa
  bool _mostrarLista = false; // Visibilidad del menú lateral

  @override
  void initState() {
    super.initState();
    _recargarLista(); // Carga los lugares al iniciar la pantalla
  }

  // Obtiene los lugares desde el servicio y actualiza la vista
  Future<void> _recargarLista() async {
    final lista = await LugarService.obtener();
    setState(() => _misLugares = lista);

    if (lista.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Si solo hay un punto, mover la cámara manualmente
        if (lista.length == 1) {
          final punto = LatLng(lista.first.latitud, lista.first.longitud);
          _mapController.move(punto, 13.0); // Zoom 
        } 
        // Si hay varios, calcular el área) y encuadramos
        else {
          final bounds = LatLngBounds.fromPoints(
            lista.map((l) => LatLng(l.latitud, l.longitud)).toList()
          );
          
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50), 
            ),
          );
        }
      });
    }
  }

  // Abre la app de Waze con las coordenadas del lugar
  Future<void> _abrirWaze(double lat, double lng) async {
    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(url);
    }
  }

  // Guardar punto exacto clicado en el mapa
  void _mostrarDialogoAgregarPunto(LatLng puntoClicado) {
    showDialog(
      context: context,
      builder: (context) => DialogLugarExacto(
        punto: puntoClicado,
        onGuardar: (lugar) async {
          setState(() => _misLugares.add(lugar));
          await LugarService.guardar(_misLugares);
          _recargarLista();
        },
      ),
    );
  }

  // Dialog de búsqueda por dirección
  void _mostrarDialogoBuscarDireccion() {
    showDialog(
      context: context,
      builder: (context) => DialogBuscarDireccion(
        centroMapa: _mapController.camera.center,
        onGuardar: (lugar) async {
          setState(() => _misLugares.add(lugar));
          await LugarService.guardar(_misLugares);
          _recargarLista();
        },
      ),
    );
  }

  // Dialog de confirmación antes de borrar un lugar
  void _mostrarDialogoEliminar(int index) {
    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        nombreLugar: _misLugares[index].nombre,
        onConfirm: () async {
          setState(() => _misLugares.removeAt(index));
          await LugarService.guardar(_misLugares);
          _recargarLista();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos para que el diseño se adapte al tamaño de pantalla
    final paddingAbajo = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final double anchoBarra = screenWidth > 450 ? 350.0 : screenWidth * 0.65; // Define el ancho lateral responsivo

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 5.0), 
          // TITULO
          child: Text(
            'Mapa', 
            style: TextStyle(
              fontFamily: 'Titulo', 
              fontSize: 28, 
              color: Colors.white,
              letterSpacing: 1.5
            )
          ),
        ), 
        backgroundColor: Colores.rojo, 
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)), 
      ),
      body: Stack( 
        children: [
          // MAPA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.416775, -3.703790), 
              initialZoom: 12.0, 
              onLongPress: (_, p) => _mostrarDialogoAgregarPunto(p),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: _misLugares.map((l) => Marker(
                  point: LatLng(l.latitud, l.longitud), 
                  width: 150, 
                  height: 100, 
                  alignment: Alignment.bottomCenter, 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end, 
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- ETIQUETA DE TEXTO LUGAR ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85), 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colores.rojo, width: 2), 
                        ),
                        child: Text(
                          l.nombre,
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.black 
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Icon(Icons.location_on, color: Colores.rojo, size: 45)
                    ],
                  ),
                )).toList()
              ),
            ],
          ),

          // Cerrar menú si se toca fuera
          if (_mostrarLista)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, 
                onTap: () => setState(() => _mostrarLista = false),
                child: Container(color: Colors.black54), // oscurece el mapa
              ),
            ),
          
          //  --- MENÚ LATERAL ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _mostrarLista ? 0 : -anchoBarra,
            top: 0, 
            bottom: 0, 
            width: anchoBarra,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(right: BorderSide(color: Colores.rojo, width: 3.0)), // Borde derecho ROJO 
              ),
              child: SafeArea(
                child: ListaLugares(
                  lugares: _misLugares,
                  onLugarTap: (l) { setState(() => _mostrarLista = false); _mapController.move(LatLng(l.latitud, l.longitud), 15.0); },
                  onDeleteTap: (i) => _mostrarDialogoEliminar(i),
                  onNavigateTap: (lat, lng) => _abrirWaze(lat, lng),
                ),
              ),
            ),
          ),
          
          // --- BOTÓN LISTA LUGARES  ---
          Positioned(
            left: 16, bottom: paddingAbajo + 16, 
            child: GestureDetector(
              onTap: () => setState(() => _mostrarLista = !_mostrarLista),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.rojo, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colores.gris, width: 3), 
                ),
                child: Icon(_mostrarLista ? Icons.close : Icons.list, color: Colors.white, size: 30), // Icono blanco
              ),
            ),
          ),

          // --- BOTÓN AÑADIR LUGAR ---
          Positioned(
            right: 16, bottom: paddingAbajo + 16, 
            child: GestureDetector(
              onTap: _mostrarDialogoBuscarDireccion,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.rojo, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colores.gris, width: 3), 
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}