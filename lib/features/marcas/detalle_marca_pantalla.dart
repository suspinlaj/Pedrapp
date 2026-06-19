import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/widgets/dialog_general.dart'; 

class DetalleMarcaPantalla extends StatefulWidget {
  final CategoriaMarca categoria;
  final Color colorFondo;

  const DetalleMarcaPantalla({super.key, required this.categoria, required this.colorFondo});

  @override
  State<DetalleMarcaPantalla> createState() => _DetalleMarcaPantallaState();
}

class _DetalleMarcaPantallaState extends State<DetalleMarcaPantalla> {

  // DIÁLOGO PARA AÑADIR/EDITAR
  void _mostrarDialogoMarca({Registro? registroAEditar, int? indexReal}) {
    final minsController = TextEditingController();
    final secsController = TextEditingController();
    
    DateTime fechaSeleccionada = registroAEditar?.fecha ?? DateTime.now();

    if (registroAEditar != null) {
      int minutos = (registroAEditar.segundosTotales / 60).floor();
      double segundos = registroAEditar.segundosTotales % 60;
      minsController.text = minutos.toString();
      secsController.text = segundos == segundos.truncateToDouble() 
          ? segundos.toInt().toString() 
          : segundos.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          
          String fechaStr = "${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}";

          return DialogGeneral(
            title: registroAEditar == null ? "Nueva Marca" : "Editar Marca",
            saveText: "Guardar",
            colorTema: widget.colorFondo, // <--- MAGIA: Le pasamos el color de la categoría
            onSave: () {
              double mins = double.tryParse(minsController.text) ?? 0.0;
              double secs = double.tryParse(secsController.text) ?? 0.0;
              double totalSegundos = (mins * 60) + secs;

              if (totalSegundos > 0) {
                setState(() {
                  if (registroAEditar != null && indexReal != null) {
                    widget.categoria.historial[indexReal] = Registro(fecha: fechaSeleccionada, segundosTotales: totalSegundos);
                  } else {
                    widget.categoria.historial.add(Registro(fecha: fechaSeleccionada, segundosTotales: totalSegundos));
                  }
                  widget.categoria.historial.sort((a, b) => a.fecha.compareTo(b.fecha));
                });
                Navigator.pop(context);
              }
            },
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila del calendario
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fecha: $fechaStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.calendar_month, color: widget.colorFondo, size: 28), 
                      onPressed: () async {
                        DateTime? seleccion = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(primary: widget.colorFondo),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (seleccion != null) {
                          setStateDialog(() => fechaSeleccionada = seleccion);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Fila de los tiempos (CON TUS BORDES)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Minutos",
                          floatingLabelStyle: TextStyle(color: widget.colorFondo, fontWeight: FontWeight.bold),
                          // Tu diseño de bordes redondeados
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: secsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Segundos",
                          floatingLabelStyle: TextStyle(color: widget.colorFondo, fontWeight: FontWeight.bold),
                          // Tu diseño de bordes redondeados
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.colorFondo, width: 2.0),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // DIÁLOGO DE BORRAR
  void _confirmarBorrado(int indexReal) {
    showDialog(
      context: context,
      builder: (context) => DialogGeneral(
        title: 'Eliminar Marca',
        saveText: 'Borrar',
        colorTema: widget.colorFondo, // <--- También le pasamos el color aquí
        onSave: () {
          setState(() {
            widget.categoria.historial.removeAt(indexReal);
          });
          Navigator.pop(context);
        },
        content: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87), 
            children: [
              const TextSpan(text: '¿Seguro que quieres borrar esta marca de '), 
              TextSpan(
                text: widget.categoria.nombre, 
                style: const TextStyle(fontWeight: FontWeight.bold), 
              ),
              const TextSpan(text: '?\n\nEsto no se puede deshacer.'), 
            ],
          ),
          textAlign: TextAlign.start, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final objetivo = CategoriaMarca.formatearTiempo(cat.objetivo);
    final mejor = CategoriaMarca.formatearTiempo(cat.mejorMarca);
    final estaLogrado = cat.progreso >= 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.nombre, style: const TextStyle(fontFamily: 'Titulo', color: Colors.white)),
        backgroundColor: widget.colorFondo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- CABECERA CON BARRA DE PROGRESO ---
          Container(
            padding: const EdgeInsets.all(20),
            color: widget.colorFondo.withOpacity(0.1),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mejor Marca", style: TextStyle(color: Colores.gris, fontSize: 14)),
                        Text(mejor == "--:--" ? "Aún sin datos" : mejor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: estaLogrado ? Colors.green : Colors.black)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Objetivo", style: TextStyle(color: Colores.gris, fontSize: 14)),
                        Text(objetivo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: cat.progreso,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    color: estaLogrado ? Colors.green : widget.colorFondo,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // --- HISTORIAL DE MARCAS ---
          Expanded(
            child: cat.historial.isEmpty
                ? const Center(
                    child: Text("Todavía no hay marcas registradas.\n¡A entrenar!", 
                    textAlign: TextAlign.center, style: TextStyle(color: Colores.gris, fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: cat.historial.length,
                    itemBuilder: (context, index) {
                      final indexReal = cat.historial.length - 1 - index;
                      final registro = cat.historial[indexReal];
                      final tiempo = CategoriaMarca.formatearTiempo(registro.segundosTotales);
                      final fechaStr = "${registro.fecha.day.toString().padLeft(2, '0')}/${registro.fecha.month.toString().padLeft(2, '0')}/${registro.fecha.year}";

                      return ListTile(
                        leading: Icon(Icons.timer, color: widget.colorFondo),
                        title: Text(tiempo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(fechaStr),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colores.gris),
                              onPressed: () => _mostrarDialogoMarca(registroAEditar: registro, indexReal: indexReal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colores.rojo),
                              onPressed: () => _confirmarBorrado(indexReal),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoMarca(), 
        backgroundColor: widget.colorFondo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Añadir Marca", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}