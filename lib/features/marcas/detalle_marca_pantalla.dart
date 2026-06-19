import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/servicios/marcas_service.dart';
import 'package:pedrapp/widgets/mapa_widgets/dialog_eliminar.dart';
import 'package:pedrapp/widgets/marcas_widgets/marca_dialog.dart';
import 'package:pedrapp/widgets/marcas_widgets/objetivo_dialog.dart';

class DetalleMarcaPantalla extends StatefulWidget {
  final CategoriaMarca categoria;
  final Color colorFondo;

  const DetalleMarcaPantalla({super.key, required this.categoria, required this.colorFondo});

  @override
  State<DetalleMarcaPantalla> createState() => _DetalleMarcaPantallaState();
}

class _DetalleMarcaPantallaState extends State<DetalleMarcaPantalla> {

  // --- 1. ABRIR DIÁLOGO DE OBJETIVO ---
  void _mostrarDialogoEditarObjetivo() {
    showDialog(
      context: context,
      builder: (context) => ObjetivoDialog( // <-- Llamamos al archivo externo
        objetivoActual: widget.categoria.objetivo,
        colorFondo: widget.colorFondo,
        onSave: (nuevoObjetivo) {
          setState(() => widget.categoria.objetivo = nuevoObjetivo);
          MarcasService().guardarCategoria(widget.categoria);
        },
      ),
    );
  }

  // --- 2. ABRIR DIÁLOGO DE MARCA ---
  void _mostrarDialogoMarca({Registro? registroAEditar, int? indexReal}) {
    showDialog(
      context: context,
      builder: (context) => DialogoMarca( // <-- Llamamos al archivo externo
        registroAEditar: registroAEditar,
        colorFondo: widget.colorFondo,
        onSave: (nuevaFecha, totalSegundos) {
          setState(() {
            if (registroAEditar != null && indexReal != null) {
              widget.categoria.historial[indexReal] = Registro(fecha: nuevaFecha, segundosTotales: totalSegundos);
            } else {
              widget.categoria.historial.add(Registro(fecha: nuevaFecha, segundosTotales: totalSegundos));
            }
            widget.categoria.historial.sort((a, b) => a.fecha.compareTo(b.fecha));
          });
          MarcasService().guardarCategoria(widget.categoria);
        },
      ),
    );
  }

  // --- 3. ABRIR DIÁLOGO DE BORRAR ---
  void _confirmarBorrado(int indexReal) {
    final registro = widget.categoria.historial[indexReal];
    final tiempoFormateado = CategoriaMarca.formatearTiempo(registro.segundosTotales);

    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        titulo: 'ELiminar Marca',
        nombreItem: tiempoFormateado, 
        finalMensaje: 'de esta categoría?\n\nEsto no se puede deshacer eh.', 
        onConfirm: () {
          setState(() => widget.categoria.historial.removeAt(indexReal));
          MarcasService().guardarCategoria(widget.categoria);
          Navigator.pop(context);
        },
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
        titleSpacing: 0,        
        centerTitle: false,
        title: Text(cat.nombre, style: const TextStyle(fontFamily: 'Titulo', color: Colors.white)),
        backgroundColor: widget.colorFondo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // CABECERA
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Objetivo ", style: TextStyle(color: Colores.gris, fontSize: 14)),
                            GestureDetector(
                              onTap: _mostrarDialogoEditarObjetivo,
                              child: Icon(Icons.edit, color: widget.colorFondo, size: 16),
                            ),
                          ],
                        ),
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

          // LISTA HISTORIAL
          Expanded(
            child: cat.historial.isEmpty
                ? const Center(
                    child: Text("Todavía no hay marcas registradas vago.\n¡A entrenar!", 
                    textAlign: TextAlign.center, style: TextStyle(color: Colores.gris, fontSize: 16)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
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