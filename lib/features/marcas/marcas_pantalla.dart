import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/features/marcas/detalle_marca_pantalla.dart';

class MarcasPantalla extends StatefulWidget {
  const MarcasPantalla({super.key});

  @override
  State<MarcasPantalla> createState() => _MarcasPantallaState();
}

class _MarcasPantallaState extends State<MarcasPantalla> {
  // Las categorías con sus iconos asignados
  List<CategoriaMarca> misCategorias = [
    CategoriaMarca(nombre: "Natacion 50", icono: Icons.waves, objetivo: 30.0),
    CategoriaMarca(nombre: "Natacion 100", icono: Icons.pool, objetivo: 65.0),
    CategoriaMarca(nombre: "Natacion buceo", icono: Icons.scuba_diving, objetivo: 25.0),
    CategoriaMarca(nombre: "Pista 200", icono: Icons.directions_run, objetivo: 26.0),
    CategoriaMarca(nombre: "Pista 1000", icono: Icons.directions_run, objetivo: 180.0),
    CategoriaMarca(nombre: "Pista 1500", icono: Icons.directions_run, objetivo: 300.0),
    CategoriaMarca(nombre: "Ritmo 5000", icono: Icons.timer, objetivo: 1200.0),
    CategoriaMarca(nombre: "Ritmo 10000", icono: Icons.timer, objetivo: 2400.0),
    CategoriaMarca(nombre: "Cuerda", icono: Icons.fitness_center, objetivo: 9.0),
  ];

  final List<Color> paletaColores = [
    Colors.blue.shade400, Colors.cyan.shade400, Colors.lightBlue.shade400, 
    Colors.orange.shade400, Colors.deepOrange.shade400, Colors.red.shade400, 
    Colors.purple.shade400, Colors.deepPurple.shade400, Colors.brown.shade400, 
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
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
            // --- PESTAÑA 1: RESUMEN GENERAL ---
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: misCategorias.length,
              separatorBuilder: (context, index) => const Divider(color: Colores.rojo),
              itemBuilder: (context, index) {
                final cat = misCategorias[index];
                
                final colorCategoria = paletaColores[index % paletaColores.length]; 
                
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
            ),

            // --- PESTAÑA 2: CUADRÍCULA DE CATEGORÍAS ---
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1, 
              ),
              itemCount: misCategorias.length,
              itemBuilder: (context, index) {
                final cat = misCategorias[index];
                final colorBoton = paletaColores[index % paletaColores.length];

                // --- SOLUCIÓN APLICADA AQUÍ ---
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                  child: Material(
                    color: colorBoton,
                    borderRadius: BorderRadius.circular(15),
                    clipBehavior: Clip.antiAlias, // <-- ESTA ES LA MAGIA QUE CORTA LO QUE SOBRA
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetalleMarcaPantalla(categoria: cat, colorFondo: colorBoton)),
                        );
                        setState(() {}); 
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
            ),
          ],
        ),
      ),
    );
  }
}