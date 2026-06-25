import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/features/marcas/detalle_marca_pantalla.dart';
import 'package:pedrapp/servicios/marcas_service.dart';
import 'package:pedrapp/widgets/marcas_widgets/nueva_categoria_dialog.dart';

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
    CategoriaMarca(id: "pista_1000", nombre: "Pista 1000", icono: Icons.directions_run, objetivo: 180.0),
    CategoriaMarca(id: "pista_1500", nombre: "Pista 1500", icono: Icons.directions_run, objetivo: 300.0),
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
    // --- ACTUALIZAR AL BORRAR ---
    List<CategoriaMarca> plantillaBase = misCategorias.where((c) => !c.id.startsWith('custom_')).toList();

    var datosNube = await _marcasServicio.cargarCategorias(plantillaBase);
    
    List<CategoriaMarca> listaOrdenada = [];
    
    // Filtrar y ordenar para que los colores nunca cambien de sitio 
    for (var plantilla in plantillaBase) {
      var encontrado = datosNube.firstWhere(
        (cat) => cat.id == plantilla.id, 
        orElse: () => plantilla 
      );
      listaOrdenada.add(encontrado);
    }

    // --- ICONOS ROTATIVOS PARA CATEGORIAS NUEVAS ---
    List<IconData> iconosGenericos = [
      Icons.star, 
      Icons.favorite, 
      Icons.local_fire_department, 
      Icons.bolt, 
      Icons.diamond
    ];

    // Extraemos de la nube SOLO las que sean nuevas
    List<CategoriaMarca> categoriasPersonalizadas = [];
    for (var nube in datosNube) {
      if (!plantillaBase.any((plantilla) => plantilla.id == nube.id)) {
        categoriasPersonalizadas.add(nube);
      }
    }

    // ordenar por antigüedad 
    categoriasPersonalizadas.sort((a, b) => a.id.compareTo(b.id));

    // añadir a la cola asignándoles el icono por orden de rotación
    for (int i = 0; i < categoriasPersonalizadas.length; i++) {
      // El operador % hace que si i=5, vuelva a coger el icono 0. 
      categoriasPersonalizadas[i].icono = iconosGenericos[i % iconosGenericos.length];
      listaOrdenada.add(categoriasPersonalizadas[i]);
    }

    setState(() {
      misCategorias = listaOrdenada; 
      cargando = false;
    });
  }

  // diálogo y guardar la nueva categoría
  void _mostrarDialogoNuevaCategoria() {
    showDialog(
      context: context,
      builder: (context) => DialogoNuevaCategoria(
        colorFondo: Colores.rojo,
        onSave: (nuevaCategoria) async {
          await _marcasServicio.guardarCategoria(nuevaCategoria); // Guarda en nube
          _cargarDatosReales(); // Recarga la pantalla
        },
      ),
    );
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
          toolbarHeight: 70.0, 
          centerTitle: false,
          
          // --- FLECHA ATRAS ---
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          
          // --- ALINEACIÓN TITULO CON FLECHA ---
          title: const Padding(
            padding: EdgeInsets.only(top: 10.0), 
            child: Text(
              'Marcas oposicion', 
              style: TextStyle(
                fontFamily: 'Titulo', 
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
          backgroundColor: Colores.rojo,
          iconTheme: const IconThemeData(color: Colors.white),
          
          // --- BORDE MENU OPCIONES ---
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0), 
            child: Stack(
              alignment: Alignment.bottomCenter, 
              children: [
                // borde
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    color: Colores.gris,
                  ),
                ),
                //  línea blanca por encima
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white, //  línea  pestaña activa
                  indicatorWeight: 3, // Mismo grosor que la gris para taparla exacta
                  tabs: [
                    Tab(icon: Icon(Icons.leaderboard), text: "Resumen"),
                    Tab(icon: Icon(Icons.grid_view), text: "Categorías"),
                  ],
                ),
              ],
            ),
          ),
        ),
        // El contenido de las pestañas
        body: TabBarView(
          children: [
            // Pestaña 1: La lista de resumen (sin botón flotante)
            _ListaResumen(categorias: misCategorias, colores: paletaColores),
            
            // Pestaña 2: La cuadrícula de botones para entrar a los detalles
            Scaffold(
              backgroundColor: Colors.transparent, // Para no tapar el fondo de la app
              body: _GridCategorias(
                categorias: misCategorias, 
                colores: paletaColores,
                alVolver: _cargarDatosReales, 
              ),
              // Ponemos el botón flotante SOLO en este Scaffold interno
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _mostrarDialogoNuevaCategoria,
                backgroundColor: Colores.rojo,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Añadir Prueba", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colores.gris, width: 3),
                ),
              ),
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
    // --- Centrar y limitar ancho de la lista para que no quede deforme en tablets 
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), 
        child: ListView.separated(
          physics: const BouncingScrollPhysics(), // Scroll con rebote suave 
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
          itemCount: categorias.length,
          separatorBuilder: (context, index) => const Divider(color: Colores.rojo),
          itemBuilder: (context, index) {
            final cat = categorias[index];
            final colorCategoria = colores[index % colores.length]; 
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
        ),
      ),
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
    // --- Calcular ancho y decidir las columnas ---
    final anchoPantalla = MediaQuery.of(context).size.width;
    final columnasDinamicas = anchoPantalla > 600 ? 5 : 3;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 80), 
      // cuántas columnas y sus espacios
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnasDinamicas, // --- RESPONSIVE
        crossAxisSpacing: 10,
        mainAxisSpacing: 10, 
        childAspectRatio: 1, 
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final colorBoton = colores[index % colores.length];

        return Container(
          // Diseño del botón
          // --- BORDE GRIS CUADROS ---
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colores.gris, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
          ),
          child: Material(
            color: colorBoton,
            borderRadius: BorderRadius.circular(12), 
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                // Navega al detalle de esa categoría
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleMarcaPantalla(categoria: cat, colorFondo: colorBoton)),
                );
                // función para refrescar la pantalla y ver si hay notas nuevas (o si se ha borrado una prueba)
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