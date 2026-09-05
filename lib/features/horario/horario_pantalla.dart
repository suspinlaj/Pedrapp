import 'package:flutter/material.dart';
import 'package:pedrapp/controller/horario_controller.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';
import 'package:pedrapp/widgets/horario_widgets/dialog_horario.dart';
import 'package:pedrapp/widgets/horario_widgets/tarjeta_bloque.dart';

class HorarioPantalla extends StatefulWidget {
  const HorarioPantalla({super.key});

  @override
  State<HorarioPantalla> createState() => _HorarioPantallaState();
}

class _HorarioPantallaState extends State<HorarioPantalla> {
  final HorarioController _controller = HorarioController();
  
  // iniciales de los días de la semana para las pestañas
  final List<String> _dias = ['L', 'M', 'x', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    // Descargar datos de Firebase nada más abrir la pantalla
    _controller.inicializar();
  }

  // --- DIÁLOGO DE EDICIÓN / CREACIÓN ---
  // ventana de edición (si le pasamos bloqueAEditar, edita; si no, crea)
  void _abrirDialogo({BloqueHorario? bloqueAEditar, required int diaActual}) {
    showDialog(
      context: context,
      builder: (context) => DialogoHorario(
        bloqueAEditar: bloqueAEditar,
        diaActual: diaActual,
        // Acción al pulsar "Guardar" en el diálogo
        onSave: (bloque, isEditing) {
          _controller.guardarBloque(bloque, isEditing);
        },
        // Acción al pulsar "Eliminar" en el diálogo
        onDelete: (idBloque) {
          _controller.eliminarBloque(idBloque);
        },
      ),
    );
  }

  // --- INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del controlador en tiempo real
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        
        // PANTALLA DE CARGA
        // Si está descargando datos, mostramos la ruedita roja girando
        if (_controller.cargando) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colores.rojo)),
          );
        }

        // PANTALLA PRINCIPAL CON PESTAÑAS
        return DefaultTabController(
          length: 7, // 7 pestañas (una por cada día de la semana)
          child: Scaffold(
            // Color fondo pantalla
            backgroundColor: Colors.white,
            
            // --- BARRA SUPERIOR (APPBAR) ---
            appBar: AppBar(
              toolbarHeight: 70.0,
              centerTitle: false,
              // Flecha atrás
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Padding(
                padding: EdgeInsets.only(top: 10.0),
                // Titulo
                child: Text(
                  'Horario',
                  style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
                ),
              ),
              // Color fondo apppbar
              backgroundColor: Colores.rojo,
              
              // --- ZONA PESTAÑAS ---
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  // LETRAS DE LOS DÍAS DE LA SEMANA
                  children: [
                    // linea negra división 
                    Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 3, color: Colores.gris)),
                    
                    // Configuración de las pestañas clickeables
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelColor: Colors.white, // Letra blanca si está seleccionada
                      unselectedLabelColor: Colors.white70, // Letra un poco transparente si no lo está
                      indicatorColor: Colors.white, // Línea blanca que subraya el día activo
                      indicatorWeight: 3, // Grosor de la línea igual al de la línea negra para taparla
                      labelStyle: const TextStyle(fontFamily: 'Titulo', fontSize: 18),
                      unselectedLabelStyle: const TextStyle(fontFamily: 'Titulo', fontSize: 16),
                      // Generar las 7 pestañas a partir de la lista _dias
                      tabs: _dias.map((dia) => Tab(text: dia)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // --- PÁGINAS POR DÍA ---
            body: TabBarView(
              // Generar 7 vistas (una para cada pestaña/día)
              children: List.generate(7, (index) {
                final diaSemana = index + 1; // 1 = Lunes, 7 = Domingo
                //  pedir al controlador solo los bloques de este día concreto y ordenados por hora
                final bloquesDelDia = _controller.obtenerBloquesDelDia(diaSemana);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800), // Límite de ancho para que no se deforme en PC
                    
                    // Texto sin tareas
                    child: bloquesDelDia.isEmpty
                        ? const Center(
                            child: Text("¿Día libre? ¿Estás seguro?", style: TextStyle(color: Colores.gris, fontSize: 16)),
                          )
                        
                        // Si hay tareas, generar lista de tarjetas
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(), 
                            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
                            itemCount: bloquesDelDia.length,
                            itemBuilder: (context, i) {
                              final bloque = bloquesDelDia[i];
                              // Dibujar tarjeta individual del horario
                              return TarjetaBloque(
                                bloque: bloque,
                                // Al tocar, abrir diálogo de educuon
                                onTap: () => _abrirDialogo(bloqueAEditar: bloque, diaActual: diaSemana),
                              );
                            },
                          ),
                  ),
                );
              }),
            ),
            
            // --- BOTÓN FLOTANTE (AÑADIR) ---
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    // saber en qué pestaña estamos  y sumar 1 para el día (1 a 7)
                    final int diaActual = DefaultTabController.of(context).index + 1;
                    // Abrimos diálogo en modo "Crear" 
                    _abrirDialogo(diaActual: diaActual);
                  },
                  backgroundColor: Colores.rojo,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Añadir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // Borde gris alrededor del botón flotante
                    side: const BorderSide(color: Colores.gris, width: 3),
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
}