import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/widgets/dialog_general.dart';
import 'package:pedrapp/widgets/marcas_widgets/tiempo_dialog.dart'; 

class DialogoMarca extends StatefulWidget {
  // Si le pasamos un registro, el diálogo se abre en modo "Editar". 
  // Si es null, se abre en modo "Nueva Marca".
  final Registro? registroAEditar;
  final Color colorFondo; // Color de la categoría para pintar los botones/bordes.
  
  // Devolver a la pantalla principal la nueva fecha y el total de segundos.
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
    // Por defecto, la fecha es "hoy". Si estamos editando, coge la fecha de ese registro.
    fechaSeleccionada = widget.registroAEditar?.fecha ?? DateTime.now();
    
    // Si estamos en modo "Editar", rellenamos las cajas de texto con su tiempo anterior.
    if (widget.registroAEditar != null) {
      int minutos = (widget.registroAEditar!.segundosTotales / 60).floor(); // Extrae los minutos
      double segundos = widget.registroAEditar!.segundosTotales % 60; // Extrae los segundos sobrantes
      
      minsController.text = minutos.toString();
      // Si los segundos son exactos (ej: 30.0), los muestra sin decimales (30). 
      // Si tienen decimales (ej: 30.55), muestra los decimales completos.
      secsController.text = segundos == segundos.truncateToDouble() ? segundos.toInt().toString() : segundos.toString();
    }
  }

  // DIALOG
  @override
  Widget build(BuildContext context) {
    // Convierte la fecha seleccionada a texto legible 
    String fechaStr = "${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}";

    return DialogGeneral(
      // Título dinámico
      title: widget.registroAEditar == null ? "Nueva Marca" : "Editar Marca",
      saveText: "Guardar",
      colorTema: widget.colorFondo,
      
      // botón "Guardar"
      onSave: () {
        // Convierte el texto de las cajas a números, sino 0
        double mins = double.tryParse(minsController.text) ?? 0.0;
        double secs = double.tryParse(secsController.text) ?? 0.0;
        
        // Convertir todo a segundos
        double totalSegundos = (mins * 60) + secs;
        
        // Guardamos tiempo mayor a 0
        if (totalSegundos > 0) {
          widget.onSave(fechaSeleccionada, totalSegundos);
          Navigator.pop(context);
        }
      },
      
      // Contenido visual del diálogo 
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILA DE LA FECHA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Fecha: $fechaStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              
              // Botón del calendario
              IconButton(
                icon: Icon(Icons.calendar_month, color: widget.colorFondo, size: 28),
                onPressed: () async {
                  // Abre el selector de fecha del móvil.
                  DateTime? seleccion = await showDatePicker(
                    context: context,
                    initialDate: fechaSeleccionada,
                    firstDate: DateTime(2020), // Límite 
                    lastDate: DateTime.now(), // No permite seleccionar fechas del futuro
                    // color de la categoría al calendario.
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
          
          // FILA DE LOS CAMPOS DE TEXTO
          Row(
            children: [
              // Caja de "Minutos" 
              TiempoDialog(label: "Minutos", controller: minsController, colorFondo: widget.colorFondo),
              const SizedBox(width: 10),
              // Separador  ":"
              const Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              // Caja de "Segundos" 
              TiempoDialog(label: "Segundos", controller: secsController, colorFondo: widget.colorFondo, isDecimal: true),
            ],
          ),
        ],
      ),
    );
  }
}