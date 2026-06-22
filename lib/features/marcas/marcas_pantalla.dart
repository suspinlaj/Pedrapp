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
  
  // Variable para  rueda de carga mientras se descargan los datos de Firebase
  bool cargando = true;

  // Definir qué pruebas hay, sus iconos y objetivos por defecto.
  // Si Firebase está vacío, se guardará esto.
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

  // Colores que se irá asignando en orden a cada categoría de la lista
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

  // Descarga los datos de Firebase en orden a mi lista
  void _cargarDatosReales() async {
    var datosNube = await _marcasServicio.cargarCategorias(misCategorias);
    
    // Filtrar y ordenar para que los colores nunca cambien de sitio
    List<CategoriaMarca> listaOrdenada = [];
    for (var plantilla in misCategorias) {
      var encontrado = datosNube.firstWhere(
        (cat) => cat.id == plantilla.id, 
        orElse: () => plantilla 
      );
      listaOrdenada.add(encontrado);
    }

    // Actualiza la pantalla ocultando la carga y mostrando la lista definitiva
    setState(() {
      misCategorias = listaOrdenada; 
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si todavía está descargando, muestra la rueda roja girando en el centro
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colores.rojo)),
      );
    }

    // Para tener las pestañas  (Resumen / Categorías)
    return DefaultTabController(
      length: 2, //  2 pestañas
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0, 
          centerTitle: false,
          title: const Text('Marcas oposicion', style: TextStyle(fontFamily: 'Titulo', color: Colors.white)),
          backgroundColor: Colores.rojo,
          iconTheme: const IconThemeData(color: Colors.white),
          // Las "pestañas" visuales debajo del título
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
        // El contenido de las pestañas
        body: TabBarView(
          children: [
            // Pestaña 1: La lista de resumen
            _ListaResumen(categorias: misCategorias, colores: paletaColores),
            // Pestaña 2: La cuadrícula de botones para entrar a los detalles
            _GridCategorias(
              categorias: misCategorias, 
              colores: paletaColores,
              alVolver: _cargarDatosReales, 
            ),
          ],
        ),
      ),
    );
  }
}


// --- WIDGETS PRIVADOS 

// Lista vertical de la primera pestaña (Resumen)
class _ListaResumen extends StatelessWidget {
  final List<CategoriaMarca> categorias;
  final List<Color> colores;

  const _ListaResumen({required this.categorias, required this.colores});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(), // Scroll con rebote suave 
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      separatorBuilder: (context, index) => const Divider(color: Colores.rojo),
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final colorCategoria = colores[index % colores.length]; // Asigna color cíclicamente
        final mejor = CategoriaMarca.formatearTiempo(cat.mejorMarca);
        final objetivo = CategoriaMarca.formatearTiempo(cat.objetivo);
        final estaLogrado = cat.progreso >= 1.0;

        // Cada fila de la lista (Icono + Títulos + Tiempo derecho)
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
              // Si cumplió el objetivo, tick verde extra
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

// Cuadrícula de la segunda pestaña (Categorías)
class _GridCategorias extends StatelessWidget {
  final List<CategoriaMarca> categorias;
  final List<Color> colores;
  final VoidCallback alVolver; // cuando se cierre la pantalla de detalles

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
      // cuántas columnas y sus espacios
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas
        crossAxisSpacing: 10, // Separación horizontal
        mainAxisSpacing: 10, // Separación vertical
        childAspectRatio: 1, // botones  cuadrados perfectos (1:1)
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final colorBoton = colores[index % colores.length];

        return Container(
          // Diseño del botón
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
                // Navega al detalle de esa categoría
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleMarcaPantalla(categoria: cat, colorFondo: colorBoton)),
                );
                // función para refrescar la pantalla y ver si hay notas nuevas
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
                      // nombre de la categoría
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