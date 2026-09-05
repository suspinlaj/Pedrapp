import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';

class TarjetaBloque extends StatelessWidget {
  final BloqueHorario bloque;
  final VoidCallback onTap;

  const TarjetaBloque({super.key, required this.bloque, required this.onTap});
  
  // Formatear objeto TimeOfDay a cadena de texto (ej. 15:30)
  String _formatTime(TimeOfDay time) {
    // Añadir ceros a la izquierda si el numero es inferior a 10
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // --- INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    // Extraer el color base asignado al bloque
    final colorBase = bloque.colorEtiqueta;
    
    return GestureDetector(
      // Detectar toque paraeditar
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // borde gris 
          border: Border.all(color: Colores.gris, width: 2),
          // ssombra sutil
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // Forzar a ocupar la misma altura máxima
        child: IntrinsicHeight(
          child: Row(
            children: [
              
              // --- FRANJA LATERAL DE COLOR ---
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: colorBase,
                  // Redondear únicamente las esquinas izquierdas para encajar 
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              
              // --- HORAS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // hora de inicio
                    Text(_formatTime(bloque.horaInicio), style: TextStyle(color: colorBase, fontWeight: FontWeight.bold, fontSize: 16)),
                    // separador 
                    Text('|', style: TextStyle(color: colorBase, fontSize: 12)),
                    // hora de fin
                    Text(_formatTime(bloque.horaFin), style: TextStyle(color: colorBase, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              
              // --- LÍNEA DIVISORIA  ---
              Container(width: 1, color: colorBase.withAlpha(76), margin: const EdgeInsets.symmetric(vertical: 10)),
              
              // --- TÍTULO ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    bloque.titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              // --- ICONO DE EDICIÓN ---
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                // icono con el color categoría
                child: Icon(Icons.edit, color: colorBase, size: 20),
              )
            ],
          ),
        ),
      ),
    );
  }
}