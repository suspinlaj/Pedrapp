import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class DialogHistorial extends StatelessWidget {
  
  // Almacenar los minutos estudiados en el día actual
  final int minutosHoy;
  
  // Almacenar todos los minutos estudiados históricamente
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
      
      // bordes 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.rojo, width: 4),
      ),
      
      // TITULO
      title: const Text(
        'HistoriaL de Estudio',
        style: TextStyle(color: Colores.rojo, fontFamily: 'Titulo', fontSize: 24),
        textAlign: TextAlign.center,
      ),
      
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          //  icono
          const Icon(Icons.local_fire_department, color: Colores.rojo, size: 50),
          const SizedBox(height: 20),
          
          //  minutos estudiados hoy
          Text('Hoy: $minutosHoy minutos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // minutos totales acumulados
          Text('Total histórico: $minutosTotales minutos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
      
      actions: [
        // botón  cerrar
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Upuu', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.bold, fontSize: 18)),
        )
      ],
    );
  }
}