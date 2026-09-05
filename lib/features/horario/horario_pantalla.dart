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
  // Instanciar controlador central
  final HorarioController _controller = HorarioController();
  final List<String> _dias = ['L', 'M', 'x', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _controller.inicializar();
  }

  // Desplegar ventana de edición
  void _abrirDialogo({BloqueHorario? bloqueAEditar, required int diaActual}) {
    showDialog(
      context: context,
      builder: (context) => DialogoHorario(
        bloqueAEditar: bloqueAEditar,
        diaActual: diaActual,
        onSave: (bloque, isEditing) {
          _controller.guardarBloque(bloque, isEditing);
        },
        onDelete: (idBloque) {
          _controller.eliminarBloque(idBloque);
        },
      ),
    );
  }

  // Construir interfaz principal
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del controlador en tiempo real
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.cargando) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colores.rojo)),
          );
        }

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            // Color fondo pantalla
            backgroundColor: Colors.white,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  // LETRAS DE LOS DÍAS DE LA SEMANA
                  children: [
                    // linea negra división
                    Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 3, color: Colores.gris)),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontFamily: 'Titulo', fontSize: 18),
                      unselectedLabelStyle: const TextStyle(fontFamily: 'Titulo', fontSize: 16),
                      tabs: _dias.map((dia) => Tab(text: dia)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            body: TabBarView(
              children: List.generate(7, (index) {
                final diaSemana = index + 1;
                final bloquesDelDia = _controller.obtenerBloquesDelDia(diaSemana);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: bloquesDelDia.isEmpty
                        ? const Center(
                            child: Text("¿Día libre? ¿Estás seguro?", style: TextStyle(color: Colores.gris, fontSize: 16)),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
                            itemCount: bloquesDelDia.length,
                            itemBuilder: (context, i) {
                              final bloque = bloquesDelDia[i];
                              return TarjetaBloque(
                                bloque: bloque,
                                onTap: () => _abrirDialogo(bloqueAEditar: bloque, diaActual: diaSemana),
                              );
                            },
                          ),
                  ),
                );
              }),
            ),
            
            // Botón flotante sensible a la pestaña seleccionada
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    final int diaActual = DefaultTabController.of(context).index + 1;
                    _abrirDialogo(diaActual: diaActual);
                  },
                  backgroundColor: Colores.rojo,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Añadir Bloque", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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