import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class SelectorTiempo extends StatelessWidget {
  final String label;
  
  // Almacenar el valor actual en minutos
  final int value;
  
  final Color colorTema;
  
  final ValueChanged<int> onChanged;

  const SelectorTiempo({
    super.key,
    required this.label,
    required this.value,
    required this.colorTema,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colores.gris, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      
      child: Column(
        children: [
          // etiqueta superior con el color del tema
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colorTema)),
          const SizedBox(height: 6),
          
          Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              // boton izquierdo para disminuir el tiempo
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                color: Colores.gris,
                onPressed: () {
                  // Calcular nuevo valor restando 5 minutos (con un límite inferior de 1 minuto)
                  int nextValue = (value <= 5) ? 1 : value - 5;
                  // Enviar nuevo valor
                  onChanged(nextValue);
                },
              ),
              
              // Mostrar el valor numérico actual en pantalla
              Text('$value min', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              
              // Crear botón derecho para aumentar el tiempo
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: colorTema,
                onPressed: () {
                  // Calcular nuevo valor sumando 5 minutos (ajustando la escala si el valor era 1)
                  int nextValue = (value == 1) ? 5 : value + 5;
                  // Enviar nuevo valore
                  onChanged(nextValue);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}