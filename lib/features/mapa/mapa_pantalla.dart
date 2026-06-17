import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/lugar.dart';
import 'package:pedrapp/servicios/lugar_service.dart';
import 'package:pedrapp/widgets/dialog_buscar_direccion.dart';
import 'package:pedrapp/widgets/dialog_lugar_exacto.dart';
import 'package:pedrapp/widgets/lista_lugares.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _recargarLista();
  }

  Future<void> _recargarLista() async {
    final lista = await LugarService.obtener();
    setState(() => _misLugares = lista);
  }

  Future<void> _abrirWaze(double lat, double lng) async {
    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(url);
    }
  }

  // --- LLAMADA AL DIÁLOGO REUTILIZABLE (Punto Exacto) ---
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

  // --- LLAMADA AL DIÁLOGO REUTILIZABLE (Búsqueda) ---
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

  @override
  Widget build(BuildContext context) {
    final paddingAbajo = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa', style: TextStyle(fontFamily: 'Titulo', fontSize: 24)), 
        backgroundColor: Colores.rojo, 
        foregroundColor: Colors.white
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn_anadir', 
        backgroundColor: Colores.rojo, foregroundColor: Colors.white,
        onPressed: _mostrarDialogoBuscarDireccion,
        child: const Icon(Icons.add, size: 30),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.416775, -3.703790), 
              initialZoom: 12.0, 
              onLongPress: (_, p) => _mostrarDialogoAgregarPunto(p)
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: _misLugares.map((l) => Marker(
                  point: LatLng(l.latitud, l.longitud), 
                  child: const Icon(Icons.location_on, color: Colores.rojo, size: 45)
                )).toList()
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _mostrarLista ? 0 : -300,
            top: 0, bottom: 0, width: 280, 
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8), 
                border: const Border(right: BorderSide(color: Colores.rojo, width: 3.0)),
                boxShadow: [if (_mostrarLista) const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]
              ),
              child: SafeArea(
                child: ListaLugares(
                  lugares: _misLugares,
                  onLugarTap: (l) { setState(() => _mostrarLista = false); _mapController.move(LatLng(l.latitud, l.longitud), 15.0); },
                  onDeleteTap: (i) async { setState(() => _misLugares.removeAt(i)); await LugarService.guardar(_misLugares); },
                  onNavigateTap: (lat, lng) => _abrirWaze(lat, lng),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16, bottom: paddingAbajo + 16, 
            child: FloatingActionButton(
              heroTag: 'btn_lista', backgroundColor: Colores.rojo, foregroundColor: Colors.white,
              onPressed: () => setState(() => _mostrarLista = !_mostrarLista),
              child: Icon(_mostrarLista ? Icons.close : Icons.list, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}