import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';

class SelectorTiempo extends StatelessWidget {
  final String label;
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colorTema)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                color: Colores.gris,
                onPressed: () {
                  int nextValue = (value <= 5) ? 1 : value - 5;
                  onChanged(nextValue);
                },
              ),
              Text('$value min', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: colorTema,
                onPressed: () {
                  int nextValue = (value == 1) ? 5 : value + 5;
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