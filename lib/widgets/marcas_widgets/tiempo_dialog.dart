import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TiempoDialog extends StatelessWidget {
  final String label; // El texto que está arriba
  final TextEditingController controller; // Extrae lo que el usuario escribe
  final Color colorFondo; // El color de la categoría 
  final bool isDecimal; 

  const TiempoDialog({
    super.key,
    required this.label, 
    required this.controller, 
    required this.colorFondo, 
    this.isDecimal = false
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller, 
        
        // Define qué teclado se abre en el móvil:
        // Si isDecimal es true, abre el teclado numérico con punto. Si no, el teclado numérico simple.
        keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        
        // Si es segundos permite decimal  Si es minutos, max 2 carac
        inputFormatters: isDecimal 
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Permite números con un único punto decimal
              LengthLimitingTextInputFormatter(5), // Máximo 5 caracteres para dar espacio a los decimales
            ]
          : [
              FilteringTextInputFormatter.digitsOnly, // Solo permite números 
              LengthLimitingTextInputFormatter(2), //  max 2 caracteres 
            ],
        
        decoration: InputDecoration(
          labelText: label, // texto 
          labelStyle: const TextStyle(fontSize: 14), // Tamaño texto
          
          floatingLabelStyle: TextStyle(color: colorFondo, fontWeight: FontWeight.bold),
          
          // Espacio con los bordes de la caja
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorFondo, width: 2.0), // Borde de color y grosor 2
            borderRadius: const BorderRadius.all(Radius.circular(10)), // Bordes redondeados
          ),
          
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorFondo, width: 2.0),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}