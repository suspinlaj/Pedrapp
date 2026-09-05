import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';

class DialogoHorario extends StatefulWidget {
  final BloqueHorario? bloqueAEditar;
  final int diaActual;
  final Function(BloqueHorario, bool) onSave;
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
    _isEditing = widget.bloqueAEditar != null;
    _tituloController = TextEditingController(text: _isEditing ? widget.bloqueAEditar!.titulo : '');
    _inicio = _isEditing ? widget.bloqueAEditar!.horaInicio : const TimeOfDay(hour: 16, minute: 0);
    _fin = _isEditing ? widget.bloqueAEditar!.horaFin : const TimeOfDay(hour: 18, minute: 0);
    
    // Asignamos por defecto el rojo de la paleta (posición 5 de la lista)
    _colorSeleccionado = _isEditing ? widget.bloqueAEditar!.colorEtiqueta : Colors.red.shade400;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  // Construir interfaz del diálogo
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.rojo, width: 3),
      ),
      title: Text(
        _isEditing ? 'Editar Bloque' : 'Nuevo BLoque',
        style: const TextStyle(fontFamily: 'Titulo', color: Colores.rojo),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: '¿Qué toca hacer? Zzz',
                labelStyle: TextStyle(color: Colores.gris), // Pone las letras en rojo
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colores.gris, width: 1),
                ),
                enabledBorder: UnderlineInputBorder( // Sustituye a unfocusedBorder
                  borderSide: BorderSide(color: Colores.rojo, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SelectorHora(
                  etiqueta: 'Inicio',
                  hora: _inicio,
                  onTap: () async {
                    final seleccion = await showTimePicker(context: context, initialTime: _inicio);
                    if (seleccion != null) setState(() => _inicio = seleccion);
                  },
                ),
                const Icon(Icons.arrow_forward, color: Colores.rojo),
                _SelectorHora(
                  etiqueta: 'Fin',
                  hora: _fin,
                  onTap: () async {
                    final seleccion = await showTimePicker(context: context, initialTime: _fin);
                    if (seleccion != null) setState(() => _fin = seleccion);
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Categoría', style: TextStyle(color: Colores.gris, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0, 
              runSpacing: 12.0, 
              // Recorremos tu paleta exacta para dibujar los círculos
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
      actions: [
        if (_isEditing && widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!(widget.bloqueAEditar!.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colores.rojo)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colores.gris)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colores.rojo),
          onPressed: () {
            if (_tituloController.text.isEmpty) return;
            
            final bloqueFinal = BloqueHorario(
              id: _isEditing ? widget.bloqueAEditar!.id : DateTime.now().millisecondsSinceEpoch.toString(),
              diaSemana: widget.diaActual,
              horaInicio: _inicio,
              horaFin: _fin,
              titulo: _tituloController.text,
              colorEtiqueta: _colorSeleccionado,
            );

            widget.onSave(bloqueFinal, _isEditing);
            Navigator.pop(context);
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Renderizar contenedor interactivo para seleccionar horas
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
              // --- BORDE ROJO ---
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

// Dibujar círculo seleccionable
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
          border: seleccionado ? Border.all(color: Colors.black54, width: 3) : null,
        ),
        child: seleccionado ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}