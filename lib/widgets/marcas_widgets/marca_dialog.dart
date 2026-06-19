import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/widgets/dialog_general.dart';
import 'package:pedrapp/widgets/marcas_widgets/tiempo_dialog.dart'; // Importamos el campo

class DialogoMarca extends StatefulWidget {
  final Registro? registroAEditar;
  final Color colorFondo;
  final Function(DateTime, double) onSave;

  const DialogoMarca({
    super.key, 
    this.registroAEditar, 
    required this.colorFondo, 
    required this.onSave
  });

  @override
  State<DialogoMarca> createState() => _DialogoMarcaState();
}

class _DialogoMarcaState extends State<DialogoMarca> {
  final minsController = TextEditingController();
  final secsController = TextEditingController();
  late DateTime fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    fechaSeleccionada = widget.registroAEditar?.fecha ?? DateTime.now();
    if (widget.registroAEditar != null) {
      int minutos = (widget.registroAEditar!.segundosTotales / 60).floor();
      double segundos = widget.registroAEditar!.segundosTotales % 60;
      minsController.text = minutos.toString();
      secsController.text = segundos == segundos.truncateToDouble() ? segundos.toInt().toString() : segundos.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    String fechaStr = "${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}";

    return DialogGeneral(
      title: widget.registroAEditar == null ? "Nueva Marca" : "Editar Marca",
      saveText: "Guardar",
      colorTema: widget.colorFondo,
      onSave: () {
        double mins = double.tryParse(minsController.text) ?? 0.0;
        double secs = double.tryParse(secsController.text) ?? 0.0;
        double totalSegundos = (mins * 60) + secs;
        if (totalSegundos > 0) {
          widget.onSave(fechaSeleccionada, totalSegundos);
          Navigator.pop(context);
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: widget.colorFondo)),
                      child: child!,
                    ),
                  );
                  if (seleccion != null) setState(() => fechaSeleccionada = seleccion);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TiempoDialog(label: "Minutos", controller: minsController, colorFondo: widget.colorFondo),
              const SizedBox(width: 10),
              const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              TiempoDialog(label: "Segundos", controller: secsController, colorFondo: widget.colorFondo, isDecimal: true),
            ],
          ),
        ],
      ),
    );
  }
}