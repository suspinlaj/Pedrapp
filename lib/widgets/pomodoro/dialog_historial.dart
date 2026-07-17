import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class DialogHistorial extends StatelessWidget {
  final int minutosHoy;
  final int minutosTotales;

  const DialogHistorial({
    super.key,
    required this.minutosHoy,
    required this.minutosTotales,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.rojo, width: 4),
      ),
      title: const Text(
        'HistoriaL de Estudio',
        style: TextStyle(color: Colores.rojo, fontFamily: 'Titulo', fontSize: 24),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colores.rojo, size: 50),
          const SizedBox(height: 20),
          Text('Hoy: $minutosHoy minutos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Total histórico: $minutosTotales minutos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Upuu', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.bold, fontSize: 18)),
        )
      ],
    );
  }
}