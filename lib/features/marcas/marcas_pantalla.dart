import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/features/marcas/detalle_marca_pantalla.dart';
import 'package:pedrapp/servicios/marcas_service.dart';

class MarcasPantalla extends StatefulWidget {
  const MarcasPantalla({super.key});

  @override
  State<MarcasPantalla> createState() => _MarcasPantallaState();
}

class _MarcasPantallaState extends State<MarcasPantalla> {
  final MarcasService _marcasServicio = MarcasService();
  bool cargando = true;

  List<CategoriaMarca> misCategorias = [
    CategoriaMarca(id: "natacion_50", nombre: "Natacion 50", icono: Icons.waves, objetivo: 30.0),
    CategoriaMarca(id: "natacion_100", nombre: "Natacion 100", icono: Icons.pool, objetivo: 65.0),
    CategoriaMarca(id: "natacion_buceo", nombre: "Natacion buceo", icono: Icons.scuba_diving, objetivo: 25.0),
    CategoriaMarca(id: "pista_200", nombre: "Pista 200", icono: Icons.directions_run, objetivo: 26.0),
    CategoriaMarca(id: "pista_1500", nombre: "Pista 1500", icono: Icons.directions_run, objetivo: 300.0),
    CategoriaMarca(id: "pista_1000", nombre: "Pista 1000", icono: Icons.directions_run, objetivo: 180.0),
    CategoriaMarca(id: "ritmo_5000", nombre: "Ritmo 5000", icono: Icons.timer, objetivo: 1200.0),
    CategoriaMarca(id: "ritmo_10000", nombre: "Ritmo 10000", icono: Icons.timer, objetivo: 2400.0),
    CategoriaMarca(id: "cuerda", nombre: "Cuerda", icono: Icons.fitness_center, objetivo: 9.0),
  ];

  final List<Color> paletaColores = [
    Colors.blue.shade400, Colors.cyan.shade400, Colors.lightBlue.shade400, 
    Colors.orange.shade400, Colors.deepOrange.shade400, Colors.red.shade400, 
    Colors.purple.shade400, Colors.deepPurple.shade400, Colors.brown.shade400, 
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosReales();
  }

  void _cargarDatosReales() async {
    var datosNube = await _marcasServicio.cargarCategorias(misCategorias);
    
    List<CategoriaMarca> listaOrdenada = [];
    for (var plantilla in misCategorias) {
      var encontrado = datosNube.firstWhere(
        (cat) => cat.id == plantilla.id, 
        orElse: () => plantilla 
      );
      listaOrdenada.add(encontrado);
    }

    setState(() {
      misCategorias = listaOrdenada; 
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colores.rojo)),
      );
    }

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0, 
          centerTitle: false,
          title: const Text('Marcas oposicion', style: TextStyle(fontFamily: 'Titulo', color: Colors.white)),
          backgroundColor: Colores.rojo,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: "Resumen"),
              Tab(icon: Icon(Icons.grid_view), text: "Categorías"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- AHORA USAMOS LOS WIDGETS REFACTORIZADOS ---
            _ListaResumen(categorias: misCategorias, colores: paletaColores),
            _GridCategorias(
              categorias: misCategorias, 
              colores: paletaColores,
              alVolver: _cargarDatosReales, // Le pasamos la función para refrescar
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// --- WIDGETS REFACTORIZADOS (Puedes moverlos a otro archivo si quieres) ---
// ============================================================================

class _ListaResumen extends StatelessWidget {
  final List<CategoriaMarca> categorias;
  final List<Color> colores;

  const _ListaResumen({required this.categorias, required this.colores});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      separatorBuilder: (context, index) => const Divider(color: Colores.rojo),
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final colorCategoria = colores[index % colores.length]; 
        final mejor = CategoriaMarca.formatearTiempo(cat.mejorMarca);
        final objetivo = CategoriaMarca.formatearTiempo(cat.objetivo);
        final estaLogrado = cat.progreso >= 1.0;

        return ListTile(
          leading: Icon(cat.icono, color: colorCategoria, size: 30), 
          title: Text(cat.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text("Objetivo: $objetivo"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mejor == "--:--" ? "Sin datos" : mejor, 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: estaLogrado ? Colors.green : Colores.rojo)
              ),
              if (estaLogrado) const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridCategorias extends StatelessWidget {
  final List<CategoriaMarca> categorias;
  final List<Color> colores;
  final VoidCallback alVolver;

  const _GridCategorias({
    required this.categorias, 
    required this.colores,
    required this.alVolver,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1, 
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final colorBoton = colores[index % colores.length];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
          ),
          child: Material(
            color: colorBoton,
            borderRadius: BorderRadius.circular(15),
            clipBehavior: Clip.antiAlias, 
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleMarcaPantalla(categoria: cat, colorFondo: colorBoton)),
                );
                alVolver(); 
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icono, color: Colors.white, size: 36), 
                      const SizedBox(height: 8),
                      Text(
                        cat.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}