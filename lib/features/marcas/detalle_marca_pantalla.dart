import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/servicios/marcas_service.dart';
import 'package:pedrapp/widgets/mapa_widgets/dialog_eliminar.dart';
import 'package:pedrapp/widgets/marcas_widgets/marca_dialog.dart';
import 'package:pedrapp/widgets/marcas_widgets/objetivo_dialog.dart';

class DetalleMarcaPantalla extends StatefulWidget {
  // Recibir la categoría a mostrar y el color asociado a ella en la cuadrícula
  final CategoriaMarca categoria;
  final Color colorFondo;

  const DetalleMarcaPantalla({super.key, required this.categoria, required this.colorFondo});

  @override
  State<DetalleMarcaPantalla> createState() => _DetalleMarcaPantallaState();
}

class _DetalleMarcaPantallaState extends State<DetalleMarcaPantalla> {
  // Mantener instancia única del servicio para evitar recrearlo en bucles o acciones 
  final MarcasService _marcasService = MarcasService();

  // --- DIÁLOGO DE OBJETIVO ---
  // Desplegar ventana para editar el objetivo de la categoria
  void _mostrarDialogoEditarObjetivo() {
    showDialog(
      context: context,
      builder: (context) => ObjetivoDialog( 
        objetivoActual: widget.categoria.objetivo,
        colorFondo: widget.colorFondo,
        onSave: (nuevoObjetivo) {
          // Actualizar la pantalla con el nuevo número y guardarlo en Firebase
          setState(() => widget.categoria.objetivo = nuevoObjetivo);
          _marcasService.guardarCategoria(widget.categoria); 
        },
      ),
    );
  }

  // --- DIÁLOGO DE MARCA ---
  // Desplegar ventana para añadir una marca nueva o editar una existente
  void _mostrarDialogoMarca({Registro? registroAEditar, int? indexReal}) {
    showDialog(
      context: context,
      builder: (context) => DialogoMarca( 
        registroAEditar: registroAEditar,
        colorFondo: widget.colorFondo,
        // Recibir la fecha elegida y el tiempo en segundos
        onSave: (nuevaFecha, totalSegundos) {
          setState(() {
            // Sustituir el registro antiguo por el nuevo al editar
            if (registroAEditar != null && indexReal != null) {
              widget.categoria.historial[indexReal] = Registro(fecha: nuevaFecha, segundosTotales: totalSegundos);
            } else {
              // Añadir a la lista de historial si es nuevo
              widget.categoria.historial.add(Registro(fecha: nuevaFecha, segundosTotales: totalSegundos));
            }
            // Ordenar lista por fecha
            widget.categoria.historial.sort((a, b) => a.fecha.compareTo(b.fecha));
          });
          // Guardar los cambios en Firebase
          _marcasService.guardarCategoria(widget.categoria); 
        },
      ),
    );
  }

  // --- DIÁLOGO DE BORRAR ---
  // Confirmar la eliminación de un registro específico
  void _confirmarBorrado(int indexReal) {
    // Buscar el registro a borrar y formatear su tiempo para mostrarlo en el texto
    final registro = widget.categoria.historial[indexReal];
    final tiempoFormateado = CategoriaMarca.formatearTiempo(registro.segundosTotales);

    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        titulo: 'ELiminar Marca', 
        nombreItem: tiempoFormateado, 
        finalMensaje: 'de esta categoría?\n\nEsto no se puede deshacer eh.', 
        // Ejecutar borrado tras confirmación
        onConfirm: () {
          // Borrar el ítem de la lista local y actualizar Firebase 
          setState(() => widget.categoria.historial.removeAt(indexReal));
          _marcasService.guardarCategoria(widget.categoria); 
          Navigator.pop(context);
        },
      ),
    );
  }

  // --- DIÁLOGO BORRAR CATEGORIA ---
  // Confirmar la eliminación de la categoría completa
  void _confirmarBorradoCategoria() {
    showDialog(
      context: context,
      builder: (context) => DialogEliminar(
        titulo: 'ELiminar PrueBa',
        nombreItem: widget.categoria.nombre, 
        finalMensaje: 'y todo su historial?\n\nPiensateló dos veces, que eres muy torpe eh.', 
        onConfirm: () async {
          // Borrar datos de Firebase 
          await _marcasService.borrarCategoria(widget.categoria.id); 
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // Construir interfaz visual de la pantalla
  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final objetivo = CategoriaMarca.formatearTiempo(cat.objetivo);
    final mejor = CategoriaMarca.formatearTiempo(cat.mejorMarca);
    
    // Comprobar si la barra de progreso ha llegado al 100% (1.0)
    final estaLogrado = cat.progreso >= 1.0;

    return Scaffold(
      // BARRA SUPERIOR 
      appBar: AppBar(
        titleSpacing: 0,        
        centerTitle: false,     
        title: Text(cat.nombre, style: const TextStyle(fontFamily: 'Titulo', color: Colors.white)),
        backgroundColor: widget.colorFondo, // Usar el color de la categoría
        iconTheme: const IconThemeData(color: Colors.white), 
        // --- BORDE GRIS  ---
        shape: const Border(bottom: BorderSide(color: Colores.gris, width: 3)),
        // --- BOTÓN DE PAPELERA  ---
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmarBorradoCategoria,
          ),
        ],
      ),

      // CUERPO PRINCIPAL
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700), // Ancho máximo controlado para web
          child: Column(
            children: [
              // CABECERA
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.colorFondo.withOpacity(0.1), // fondo translúcido
                    borderRadius: BorderRadius.circular(16), // bordes
                    border: Border.all(color: widget.colorFondo, width: 2), //  color del tema borde
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Mejor Marca
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Mejor Marca", style: TextStyle(color: Colores.gris, fontSize: 14)), 
                              // Mostrar el tiempo en verde si se logró el objetivo, si no, en negro
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
                          value: cat.progreso, // Determinar nivel de relleno (de 0.0 a 1.0)
                          minHeight: 12, 
                          backgroundColor: Colors.grey.shade300, // color del fondo vacio 
                          color: estaLogrado ? Colors.green : widget.colorFondo, // color del relleno
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // línea divisoria c
              Divider(color: widget.colorFondo, height: 1, thickness: 1),

              // LISTA HISTORIAL 
              Expanded(
                //  Mostrar texto si no hay marcas; mostrar lista si hay registros
                child: cat.historial.isEmpty
                    ? const Center(
                        child: Text("Todavía no hay marcas registradas vago.\n¡A entrenar!", 
                        textAlign: TextAlign.center, style: TextStyle(color: Colores.gris, fontSize: 16)),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(), // Añadir efecto de rebote al hacer scroll 
                        itemCount: cat.historial.length,
                        itemBuilder: (context, index) {
                          // Mostrar los registros más nuevos arriba del todo
                          final indexReal = cat.historial.length - 1 - index;
                          final registro = cat.historial[indexReal];
                          
                          // Extraer textos a mostrar (tiempo y fecha)
                          final tiempo = CategoriaMarca.formatearTiempo(registro.segundosTotales);
                          
                          // Formatear la fecha a DD/MM/YYYY
                          final fechaStr = "${registro.fecha.day.toString().padLeft(2, '0')}/${registro.fecha.month.toString().padLeft(2, '0')}/${registro.fecha.year}";

                          // Dibujar el diseño de cada fila de la lista
                          return ListTile(
                            leading: Icon(Icons.timer, color: widget.colorFondo), // Dibujar icono a la izquierda
                            title: Text(tiempo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Escribir tiempo en grande
                            subtitle: Text(fechaStr), // Escribir fecha en pequeño
                            trailing: Row( // Agrupar botones a la derecha de la fila
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colores.gris, width: 3),
        ),
      ),
    );
  }
}