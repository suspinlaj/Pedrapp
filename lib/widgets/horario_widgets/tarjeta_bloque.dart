import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';

class TarjetaBloque extends StatelessWidget {
  final BloqueHorario bloque;
  final VoidCallback onTap;

  const TarjetaBloque({super.key, required this.bloque, required this.onTap});

  // Formatear hora (ej. 15:30)
  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Dibujar la tarjeta individual
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colores.gris, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: bloque.colorEtiqueta,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatTime(bloque.horaInicio), style: TextStyle(color: bloque.colorEtiqueta, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('|', style: TextStyle(color: bloque.colorEtiqueta, fontSize: 12)),
                    Text(_formatTime(bloque.horaFin), style: TextStyle(color: bloque.colorEtiqueta, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              Container(width: 1, color: bloque.colorEtiqueta.withOpacity(0.3), margin: const EdgeInsets.symmetric(vertical: 10)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    bloque.titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    // --- SE HAN QUITADO LOS LÍMITES DE LÍNEAS AQUÍ ---
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                // --- LÁPIZ DEL COLOR DE LA CATEGORÍA ---
                child: Icon(Icons.edit, color: bloque.colorEtiqueta, size: 20),
              )
            ],
          ),
        ),
      ),
    );
  }
}