import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

// Definir modelo de datos para las franjas horarias
class BloqueHorario {
  String id;
  int diaSemana; // 1 = Lunes, 7 = Domingo
  TimeOfDay horaInicio;
  TimeOfDay horaFin;
  String titulo;
  Color colorEtiqueta;

  BloqueHorario({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.titulo,
    required this.colorEtiqueta,
  });
}

class HorarioPantalla extends StatefulWidget {
  const HorarioPantalla({super.key});

  @override
  State<HorarioPantalla> createState() => _HorarioPantallaState();
}

class _HorarioPantallaState extends State<HorarioPantalla> {
  // Inicializar lista local de bloques (En el futuro esto se cargará de Firebase/SharedPreferences)
  List<BloqueHorario> _bloques = [];

  // Definir pestañas para los días de la semana
  final List<String> _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  // Cargar un horario base de ejemplo basado en el esquema original
  void _cargarDatosIniciales() {
    _bloques = [
      BloqueHorario(
        id: '1', diaSemana: 1, horaInicio: const TimeOfDay(hour: 15, minute: 30), 
        horaFin: const TimeOfDay(hour: 17, minute: 0), titulo: 'Estudio General', colorEtiqueta: Colores.rojo
      ),
      BloqueHorario(
        id: '2', diaSemana: 1, horaInicio: const TimeOfDay(hour: 17, minute: 0), 
        horaFin: const TimeOfDay(hour: 17, minute: 30), titulo: 'Descanso / Merienda', colorEtiqueta: Colores.amarillo
      ),
      BloqueHorario(
        id: '3', diaSemana: 2, horaInicio: const TimeOfDay(hour: 18, minute: 0), 
        horaFin: const TimeOfDay(hour: 20, minute: 0), titulo: 'A VER A SUSI', colorEtiqueta: Colors.green
      ),
    ];
  }

  // Convertir TimeOfDay a minutos totales para facilitar la ordenación lógica
  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  // Formatear hora para mostrarla en pantalla (ej. 15:30)
  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Desplegar diálogo para añadir o editar un bloque horario
  void _mostrarDialogoEdicion({BloqueHorario? bloqueAEditar, required int diaActual}) {
    final isEditing = bloqueAEditar != null;
    
    // Configurar controladores con datos existentes o valores por defecto
    final tituloController = TextEditingController(text: isEditing ? bloqueAEditar.titulo : '');
    TimeOfDay inicio = isEditing ? bloqueAEditar.horaInicio : const TimeOfDay(hour: 16, minute: 0);
    TimeOfDay fin = isEditing ? bloqueAEditar.horaFin : const TimeOfDay(hour: 18, minute: 0);
    // Establecer un color por defecto que exista en la nueva lista
    Color colorSeleccionado = isEditing ? bloqueAEditar.colorEtiqueta : Colors.red.shade400;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                isEditing ? 'Editar Bloque' : 'Nuevo Bloque',
                style: const TextStyle(fontFamily: 'Titulo', color: Colores.rojo),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de texto para el nombre de la actividad
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: '¿Qué toca hacer?',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colores.rojo)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Selectores de hora de inicio y fin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SelectorHora(
                          etiqueta: 'Inicio',
                          hora: inicio,
                          onTap: () async {
                            final seleccion = await showTimePicker(context: context, initialTime: inicio);
                            if (seleccion != null) setStateDialog(() => inicio = seleccion);
                          },
                        ),
                        const Icon(Icons.arrow_forward, color: Colores.gris),
                        _SelectorHora(
                          etiqueta: 'Fin',
                          hora: fin,
                          onTap: () async {
                            final seleccion = await showTimePicker(context: context, initialTime: fin);
                            if (seleccion != null) setStateDialog(() => fin = seleccion);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // Selector de color para categorizar
                    const Text('Categoría', style: TextStyle(color: Colores.gris, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    // Utilizar Wrap para permitir salto de línea automático si no caben
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12.0, // Separación horizontal entre círculos
                      runSpacing: 12.0, // Separación vertical entre filas
                      children: [
                        _BotonColor(color: Colors.blue.shade400, seleccionado: colorSeleccionado == Colors.blue.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.blue.shade400)),
                        _BotonColor(color: Colors.cyan.shade400, seleccionado: colorSeleccionado == Colors.cyan.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.cyan.shade400)),
                        _BotonColor(color: Colors.lightBlue.shade400, seleccionado: colorSeleccionado == Colors.lightBlue.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.lightBlue.shade400)),
                        _BotonColor(color: Colors.orange.shade400, seleccionado: colorSeleccionado == Colors.orange.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.orange.shade400)),
                        _BotonColor(color: Colors.deepOrange.shade400, seleccionado: colorSeleccionado == Colors.deepOrange.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.deepOrange.shade400)),
                        _BotonColor(color: Colors.red.shade400, seleccionado: colorSeleccionado == Colors.red.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.red.shade400)),
                        _BotonColor(color: Colors.purple.shade400, seleccionado: colorSeleccionado == Colors.purple.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.purple.shade400)),
                        _BotonColor(color: Colors.deepPurple.shade400, seleccionado: colorSeleccionado == Colors.deepPurple.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.deepPurple.shade400)),
                        _BotonColor(color: Colors.brown.shade400, seleccionado: colorSeleccionado == Colors.brown.shade400, onTap: () => setStateDialog(() => colorSeleccionado = Colors.brown.shade400)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                // Botón para eliminar registro (solo visible al editar)
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() => _bloques.removeWhere((b) => b.id == bloqueAEditar.id));
                      Navigator.pop(context);
                    },
                    child: const Text('Eliminar', style: TextStyle(color: Colores.rojo)),
                  ),
                // Botón para cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colores.gris)),
                ),
                // Botón para guardar cambios
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colores.rojo),
                  onPressed: () {
                    if (tituloController.text.isEmpty) return;
                    
                    setState(() {
                      if (isEditing) {
                        bloqueAEditar.titulo = tituloController.text;
                        bloqueAEditar.horaInicio = inicio;
                        bloqueAEditar.horaFin = fin;
                        bloqueAEditar.colorEtiqueta = colorSeleccionado;
                      } else {
                        _bloques.add(BloqueHorario(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          diaSemana: diaActual,
                          horaInicio: inicio,
                          horaFin: fin,
                          titulo: tituloController.text,
                          colorEtiqueta: colorSeleccionado,
                        ));
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configurar controlador de pestañas para los 7 días de la semana
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 70.0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              'Horario',
              style: TextStyle(fontFamily: 'Titulo', color: Colors.white, fontSize: 28),
            ),
          ),
          backgroundColor: Colores.rojo,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 3, color: Colores.gris)),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: _dias.map((dia) => Tab(text: dia)).toList(),
                ),
              ],
            ),
          ),
        ),
        
        // Generar vistas independientes para cada día
        body: TabBarView(
          children: List.generate(7, (index) {
            final diaSemana = index + 1;
            
            // Filtrar y ordenar los bloques correspondientes al día actual
            final bloquesDelDia = _bloques.where((b) => b.diaSemana == diaSemana).toList()
              ..sort((a, b) => _timeToMinutes(a.horaInicio).compareTo(_timeToMinutes(b.horaInicio)));

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Aplicar diseño responsivo
                child: bloquesDelDia.isEmpty
                    ? const Center(
                        child: Text("Día libre. ¡Aprovecha para descansar!", style: TextStyle(color: Colores.gris, fontSize: 16)),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
                        itemCount: bloquesDelDia.length,
                        itemBuilder: (context, i) {
                          final bloque = bloquesDelDia[i];
                          
                          // Construir tarjeta individual del bloque horario
                          return GestureDetector(
                            onTap: () => _mostrarDialogoEdicion(bloqueAEditar: bloque, diaActual: diaSemana),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colores.gris.withOpacity(0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // Pintar franja lateral con el color asignado a la categoría
                                    Container(
                                      width: 12,
                                      decoration: BoxDecoration(
                                        color: bloque.colorEtiqueta,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                      ),
                                    ),
                                    // Mostrar bloque de horas a la izquierda
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(_formatTime(bloque.horaInicio), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const Text('|', style: TextStyle(color: Colores.gris, fontSize: 12)),
                                          Text(_formatTime(bloque.horaFin), style: const TextStyle(color: Colores.gris, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    // Añadir divisor vertical interno
                                    Container(width: 1, color: Colores.gris.withOpacity(0.3), margin: const EdgeInsets.symmetric(vertical: 10)),
                                    // Imprimir título de la tarea a la derecha
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          bloque.titulo,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 16.0),
                                      child: Icon(Icons.edit, color: Colores.gris, size: 20),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            );
          }),
        ),
        
        // Construir botón flotante sensible al día seleccionado
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                final int diaActual = DefaultTabController.of(context).index + 1;
                _mostrarDialogoEdicion(diaActual: diaActual);
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
  }
}

// --- WIDGETS PRIVADOS AUXILIARES ---

// Renderizar contenedor interactivo para seleccionar horas en el diálogo
class _SelectorHora extends StatelessWidget {
  final String etiqueta;
  final TimeOfDay hora;
  final VoidCallback onTap;

  const _SelectorHora({required this.etiqueta, required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(etiqueta, style: const TextStyle(color: Colores.gris, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colores.gris),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$h:$m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// Dibujar círculo seleccionable para categorizar el bloque por colores
class _BotonColor extends StatelessWidget {
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonColor({required this.color, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(seleccionado ? 1.0 : 0.5),
          shape: BoxShape.circle,
          border: seleccionado ? Border.all(color: Colors.black54, width: 3) : null,
        ),
        child: seleccionado ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
