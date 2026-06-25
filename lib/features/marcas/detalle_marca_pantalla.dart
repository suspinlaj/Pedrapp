import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/servicios/marcas_service.dart';
import 'package:pedrapp/widgets/mapa_widgets/dialog_eliminar.dart';
import 'package:pedrapp/widgets/marcas_widgets/marca_dialog.dart';
import 'package:pedrapp/widgets/marcas_widgets/objetivo_dialog.dart';

class DetalleMarcaPantalla extends StatefulWidget {
  // Recibe la categoría a mostrar y el color asociado a ella en la cuadrícula.
  final CategoriaMarca categoria;
  final Color colorFondo;

  const DetalleMarcaPantalla({super.key, required this.categoria, required this.colorFondo});

  @override
  State<DetalleMarcaPantalla> createState() => _DetalleMarcaPantallaState();
}

class _DetalleMarcaPantallaState extends State<DetalleMarcaPantalla> {

  // --- DIÁLOGO DE OBJETIVO ---
  // para poder editar el objetivo de la categoria
  void _mostrarDialogoEditarObjetivo() {
    showDialog(
      context: context,
      builder: (context) => ObjetivoDialog( 
        objetivoActual: widget.categoria.objetivo,
        colorFondo: widget.colorFondo,
        onSave: (nuevoObjetivo) {
          // Actualiza la pantalla con el nuevo número y lo guarda en Firebase.
          setState(() => widget.categoria.objetivo = nuevoObjetivo);
          MarcasService().guardarCategoria(widget.categoria);
        },
      ),
    );
  }

  // --- DIÁLOGO DE MARCA ---
  // para añadir una marca nueva o editar una existente.
  void _mostrarDialogoMarca({Registro? registroAEditar, int? indexReal}) {
    showDialog(
      context: context,
      builder: (context) => DialogoMarca( 
        registroAEditar: registroAEditar,
        colorFondo: widget.colorFondo,
        //  recibe la fecha elegida y el tiempo en segundos.
        onSave: (nuevaFecha, totalSegundos) {
          setState(() {
            // Si se está editando, sustituye el registro antiguo por el nuevo.
            if (registroAEditar != null && indexReal != null) {
              widget.categoria.historial[indexReal] = Registro(fecha: nuevaFecha, segundosTotales: totalSegundos);
            } else {
            // Si es nuevo, lo añade a la lista de historial.
              widget.categoria.historial.add(Registro(fecha: nuevaFecha, segundosTotales: totalSegundos));
            }
            // Ordenar por fecha
            widget.categoria.historial.sort((a, b) => a.fecha.compareTo(b.fecha));
          });
          // Guarda los cambios en Firebase
          MarcasService().guardarCategoria(widget.categoria);
        },
      ),
    );
  }

  // --- DIÁLOGO DE BORRAR ---
  void _confirmarBorrado(int indexReal) {
    // Busca el registro  a borrar y formatea su tiempo para mostrarlo en el texto.
    final registro = widget.categoria.historial[indexReal];
    final tiempoFormateado = CategoriaMarca.formatearTiempo(registro.segundosTotales);

    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        titulo: 'ELiminar Marca', 
        nombreItem: tiempoFormateado, 
        finalMensaje: 'de esta categoría?\n\nEsto no se puede deshacer eh.', 
        // confirma que sí quiere borrar.
        onConfirm: () {
          // Borra el ítem de la lista local, actualiza Firebase 
          setState(() => widget.categoria.historial.removeAt(indexReal));
          MarcasService().guardarCategoria(widget.categoria);
          Navigator.pop(context);
        },
      ),
    );
  }

  // --- DIÁLOGO BORRAR CATEGORIA ---
  // Elimina la categoría 
  void _confirmarBorradoCategoria() {
    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        titulo: 'ELiminar PrueBa',
        nombreItem: widget.categoria.nombre, 
        finalMensaje: 'y todo su historial?\n\nPiensateló dos veces, que eres muy torpe eh.', 
        onConfirm: () async {
          // borrar de Firebase 
          await MarcasService().borrarCategoria(widget.categoria.id);
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  // interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final objetivo = CategoriaMarca.formatearTiempo(cat.objetivo);
    final mejor = CategoriaMarca.formatearTiempo(cat.mejorMarca);
    // Comprueba si la barra de progreso ha llegado al 100% (1.0).
    final estaLogrado = cat.progreso >= 1.0;

    return Scaffold(
      // BARRA SUPERIOR 
      appBar: AppBar(
        titleSpacing: 0,        
        centerTitle: false,     
        title: Text(cat.nombre, style: const TextStyle(fontFamily: 'Titulo', color: Colors.white)),
        backgroundColor: widget.colorFondo, // Usa el color de la categoría.
        iconTheme: const IconThemeData(color: Colors.white), 
        // --- BORDE GRIS  ---
        shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
        // --- BOTÓN DE PAPELERA  ---
        actions: [
          // Eliminamos la condición if para que siempre salga el botón
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmarBorradoCategoria,
          ),
        ],
      ),

      // CUERPO PRINCIPAL
      // Centrar y limitae el ancho para tablets
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Ancho máximo
          child: Column(
            children: [
              // CABECERA (Zona de estadísticas superior)
              Container(
                padding: const EdgeInsets.all(20),
                // Fondo con el color de la categoría 
                color: widget.colorFondo.withOpacity(0.1),
                child: Column(
                  children: [
                    // Fila con los dos bloques: Mejor Marca (Izquierda) y Objetivo (Derecha).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mejor Marca
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Mejor Marca", style: TextStyle(color: Colores.gris, fontSize: 14)),
                            // Muestra el tiempo en verde si se logró el objetivo, si no, en negro.
                            Text(mejor == "--:--" ? "Aún sin datos" : mejor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: estaLogrado ? Colors.green : Colors.black)),
                          ],
                        ),
                        // Objetivo
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
                    // BARRA DE PROGRESO
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10), 
                      child: LinearProgressIndicator(
                        value: cat.progreso, // Cuánto se llena (de 0.0 a 1.0).
                        minHeight: 12, 
                        backgroundColor: Colors.grey.shade300, // Color del fondo vacío.
                        color: estaLogrado ? Colors.green : widget.colorFondo, // Color del relleno.
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, thickness: 1),

              // LISTA HISTORIAL 
              Expanded(
                //  Si no hay marcas, muestra texto; si hay, muestra la lista.
                child: cat.historial.isEmpty
                    ? const Center(
                        child: Text("Todavía no hay marcas registradas vago.\n¡A entrenar!", 
                        textAlign: TextAlign.center, style: TextStyle(color: Colores.gris, fontSize: 16)),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(), // Efecto de rebote al hacer scroll 
                        itemCount: cat.historial.length,
                        itemBuilder: (context, index) {
                          // mostrar los registros más nuevos arriba del todo.
                          final indexReal = cat.historial.length - 1 - index;
                          final registro = cat.historial[indexReal];
                          
                          // extos a mostrar (tiempo y fecha).
                          final tiempo = CategoriaMarca.formatearTiempo(registro.segundosTotales);
                          final fechaStr = "${registro.fecha.day.toString().padLeft(2, '0')}/${registro.fecha.month.toString().padLeft(2, '0')}/${registro.fecha.year}";

                          // Diseño de cada fila de la lista
                          return ListTile(
                            leading: Icon(Icons.timer, color: widget.colorFondo), // Icono a la izquierda
                            title: Text(tiempo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Tiempo en grande
                            subtitle: Text(fechaStr), // Fecha en pequeño
                            trailing: Row( // Botones a la derecha de la fila
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botón de editar
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colores.gris),
                                  onPressed: () => _mostrarDialogoMarca(registroAEditar: registro, indexReal: indexReal),
                                ),
                                // Botón de borrar
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
        ),
      ),
      // BOTÓN FLOTANTE AÑADIR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoMarca(), 
        backgroundColor: widget.colorFondo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Añadir Marca", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // --- BORDE GRIS Y CURVA DEL BOTÓN AÑADIDOS ---
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colores.gris, width: 3),
        ),
      ),
    );
  }
}