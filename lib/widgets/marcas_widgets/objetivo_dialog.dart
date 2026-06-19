import 'package:flutter/material.dart';
import 'package:pedrapp/widgets/dialog_general.dart';
import 'package:pedrapp/widgets/marcas_widgets/tiempo_dialog.dart';

class ObjetivoDialog extends StatefulWidget {
  final double objetivoActual;
  final Color colorFondo;
  final Function(double) onSave;

  const ObjetivoDialog({
    super.key, 
    required this.objetivoActual, 
    required this.colorFondo, 
    required this.onSave
  });

  @override
  State<ObjetivoDialog> createState() => _ObjetivoDialogState();
}

class _ObjetivoDialogState extends State<ObjetivoDialog> {
  final minsController = TextEditingController();
  final secsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    int minutos = (widget.objetivoActual / 60).floor();
    double segundos = widget.objetivoActual % 60;
    minsController.text = minutos.toString();
    secsController.text = segundos == segundos.truncateToDouble() ? segundos.toInt().toString() : segundos.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: "Editar oBjetivo",
      saveText: "Guardar",
      colorTema: widget.colorFondo,
      onSave: () {
        double mins = double.tryParse(minsController.text) ?? 0.0;
        double secs = double.tryParse(secsController.text) ?? 0.0;
        double totalSegundos = (mins * 60) + secs;
        if (totalSegundos > 0) {
          widget.onSave(totalSegundos);
          Navigator.pop(context);
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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