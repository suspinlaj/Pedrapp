import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';

class DialogoHorario extends StatefulWidget {
  // Al pasar un bloque, el diálogo se abre en modo "Editar". 
  // En caso de ser null, se abre en modo "Nuevo Bloque".
  final BloqueHorario? bloqueAEditar;
  
  // Día de la semana en el que se está añadiendo el bloque
  final int diaActual;
  
  // Función para devolver a la pantalla principal el bloque modificado o creado
  final Function(BloqueHorario, bool) onSave;
  
  // Función opcional para borrar un bloque (modo edición)
  final Function(String)? onDelete;

  const DialogoHorario({
    super.key,
    this.bloqueAEditar,
    required this.diaActual,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<DialogoHorario> createState() => _DialogoHorarioState();
}

class _DialogoHorarioState extends State<DialogoHorario> {
  late TextEditingController _tituloController;
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  late Color _colorSeleccionado;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    // Detectar modo edición si el bloque recibido no es nulo
    _isEditing = widget.bloqueAEditar != null;
    
    // edición -> rellenar el texto con el título anterior; caso contrario, dejar vacío
    _tituloController = TextEditingController(text: _isEditing ? widget.bloqueAEditar!.titulo : '');
    
    // edición -> cargar las horas anteriores; caso contrario, aplicar 16:00 a 18:00 por defecto
    _inicio = _isEditing ? widget.bloqueAEditar!.horaInicio : const TimeOfDay(hour: 16, minute: 0);
    _fin = _isEditing ? widget.bloqueAEditar!.horaFin : const TimeOfDay(hour: 18, minute: 0);
    
    // Asignar por defecto el rojo de la paleta
    _colorSeleccionado = _isEditing ? widget.bloqueAEditar!.colorEtiqueta : Colores.paleta[5];
  }

  @override
  void dispose() {
    // Liberar memoria del controlador al cerrar el diálogo
    _tituloController.dispose();
    super.dispose();
  }

  // --- DIÁLOGO ---
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      
      // Bordes y forma de la ventana flotante
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.rojo, width: 3),
      ),
      
      // Título dinámico
      title: Text(
        _isEditing ? 'Editar Bloque' : 'Nuevo BLoque',
        style: const TextStyle(fontFamily: 'Titulo', color: Colores.rojo),
      ),
      
      // Contenido central del diálogo (
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // --- TÍTULO DE TAREA ---
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título Tarea Zzz....',
                labelStyle: TextStyle(color: Colores.gris), 
                // Color línea inferior activo
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colores.gris, width: 1),
                ),
                // Color línea inferior inactivo
                enabledBorder: UnderlineInputBorder( 
                  borderSide: BorderSide(color: Colores.rojo, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- FILA DE SELECCIÓN DE HORAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Selector Hora de Inicio
                _SelectorHora(
                  etiqueta: 'Inicio',
                  hora: _inicio,
                  onTap: () async {
                    // Abrir reloj nativo del sistema
                    final seleccion = await showTimePicker(context: context, initialTime: _inicio);
                    if (seleccion != null) setState(() => _inicio = seleccion);
                  },
                ),
                // Flecha indicadora central
                const Icon(Icons.arrow_forward, color: Colores.rojo),
                // Selector Hora de Fin
                _SelectorHora(
                  etiqueta: 'Fin',
                  hora: _fin,
                  onTap: () async {
                    // Abrir reloj nativo del sistema
                    final seleccion = await showTimePicker(context: context, initialTime: _fin);
                    if (seleccion != null) setState(() => _fin = seleccion);
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // --- SELECCIÓN COLOR ---
            const Text('Categoría', style: TextStyle(color: Colores.gris, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0, // Separación horizontal entre círculos
              runSpacing: 12.0, // Separación vertical entre filas de círculos
              // Recorrer la paleta de colores 
              children: Colores.paleta.map((colorDeLista) {
                return _BotonColor(
                  color: colorDeLista, 
                  seleccionado: _colorSeleccionado == colorDeLista, 
                  onTap: () => setState(() => _colorSeleccionado = colorDeLista)
                );
              }).toList(),
            ),
          ],
        ),
      ),
      
      // --- BOTONES INFERIORES---
      actions: [
        // Botón Eliminar 
        if (_isEditing && widget.onDelete != null)
          TextButton(
            onPressed: () {
              // Llamar a la función de borrado pasando el ID del bloque
              widget.onDelete!(widget.bloqueAEditar!.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colores.rojo)),
          ),
          
        // Botón Cancelar
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colores.gris)),
        ),
        
        // Botón Guardar
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colores.rojo),
          onPressed: () {
            // Evitar guardar si el campo de título se encuentra vacío
            if (_tituloController.text.isEmpty) return;
            
            final bloqueFinal = BloqueHorario(
              // En modo edición, mantener el ID original; al crear, generar uno nuevo basado en el tiempo
              id: _isEditing ? widget.bloqueAEditar!.id : DateTime.now().millisecondsSinceEpoch.toString(),
              diaSemana: widget.diaActual,
              horaInicio: _inicio,
              horaFin: _fin,
              titulo: _tituloController.text,
              colorEtiqueta: _colorSeleccionado,
            );

            // Enviar el bloque resultante a la vista principal
            widget.onSave(bloqueFinal, _isEditing);
            Navigator.pop(context); // Cerrar diálogo
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// --- WIDGETS INTERNOS ---

// Renderizar contenedor interactivo para seleccionar horas (Ej: 16:00)
class _SelectorHora extends StatelessWidget {
  final String etiqueta; // Título superior (Inicio o Fin)
  final TimeOfDay hora; // Valor temporal actual
  final VoidCallback onTap; // Acción a ejecutar al tocar

  const _SelectorHora({required this.etiqueta, required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Añadir ceros a la izquierda si el valor numérico es inferior a 10 (ej: 09:05)
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
              // --- BORDE ROJO DE LA CAJA HORARIA ---
              border: Border.all(color: Colores.rojo, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$h:$m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// BOTON COLOR
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
          color: color,
          shape: BoxShape.circle,
          // Dibujar borde gris oscuro en caso de estar seleccionado
          border: seleccionado ? Border.all(color: Colors.black54, width: 3) : null,
        ),
        // Superponer icono de confirmación blanco en caso de estar seleccionado
        child: seleccionado ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}