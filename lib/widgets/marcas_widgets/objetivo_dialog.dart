import 'package:flutter/material.dart';
import 'package:pedrapp/widgets/dialog_general.dart';
import 'package:pedrapp/widgets/marcas_widgets/tiempo_dialog.dart';

class ObjetivoDialog extends StatefulWidget {
  final double objetivoActual; // tiempo objetivo actualmente 
  final Color colorFondo; // color de la categoría para pintar los bordes.
  final Function(double) onSave; // La función que devolverá el nuevo tiempo cuando pulse Guardar.

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
  // Controladores para extraer el texto que el usuario escriba de las cajas.
  final minsController = TextEditingController();
  final secsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    int minutos = (widget.objetivoActual / 60).floor(); // Saca los minutos 
    double segundos = widget.objetivoActual % 60; // Saca los segundos 
    
    // Rellenar cajas de texto con los valores para que el usuario pueda editarlos
    minsController.text = minutos.toString();
    
    // Rellenar segundos
    // Si los segundos son exactos (ej: 30.0), los muestra sin decimales (30). 
    // Si tienen decimales completos (ej: 30.55), los muestra todos sin recortar.
    secsController.text = segundos == segundos.truncateToDouble() ? segundos.toInt().toString() : segundos.toString();
  }

  // dialog
  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: "Editar oBjetivo", // Título
      saveText: "Guardar", // Texto botón
      colorTema: widget.colorFondo, // botón con el color de la prueba
      
      // botón "Guardar"
      onSave: () {
        double mins = double.tryParse(minsController.text) ?? 0.0;
        double secs = double.tryParse(secsController.text) ?? 0.0;
        
        // juntar minutos y segundos en un solo número total
        double totalSegundos = (mins * 60) + secs;
        
        // Solo guarda si el objetivo no es 0 
        if (totalSegundos > 0) {
          // Envíar nuevo objetivo para que lo guarde en Firebase.
          widget.onSave(totalSegundos);
          Navigator.pop(context);
        }
      },
      
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Row(
            children: [
              // Caja izquierda: Minutos
              TiempoDialog(label: "Minutos", controller: minsController, colorFondo: widget.colorFondo),
              const SizedBox(width: 10),
              
              // Separador ":"
              const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              
              // Caja derecha: Segundos 
              TiempoDialog(label: "Segundos", controller: secsController, colorFondo: widget.colorFondo, isDecimal: true),
            ],
          ),
        ],
      ),
    );
  }
}