import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/lugar.dart';

class ListaLugares extends StatelessWidget {
  final List<Lugar> lugares;
  final Function(Lugar) onLugarTap;
  final Function(int) onDeleteTap;
  final Function(double, double) onNavigateTap;

  const ListaLugares({
    super.key, 
    required this.lugares, 
    required this.onLugarTap, 
    required this.onDeleteTap, 
    required this.onNavigateTap
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text('Lugares Guardados', style: TextStyle(color: Colores.gris, fontFamily: 'Subtitulo', fontSize: 37, fontWeight: FontWeight.bold)),
        ),
        const Divider(color: Colores.rojo, thickness: 2.5),
        Expanded(
          child: lugares.isEmpty
              ? const Center(child: Text('Añade tu primer lugar'))
              : ListView.separated(
                  itemCount: lugares.length,
                  separatorBuilder: (_, __) => const Divider(color: Colores.rojo, indent: 40.0, endIndent: 40.0, height: 1.0, thickness: 1.5),
                  itemBuilder: (context, index) {
                    final lugar = lugares[index];
                    return InkWell(
                      onTap: () => onLugarTap(lugar),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colores.rojo, size: 24),
                            const SizedBox(width: 10),
                            Expanded(child: Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => onNavigateTap(lugar.latitud, lugar.longitud),
                                  child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.navigation, color: Colores.gris, size: 22)),
                                ),
                                InkWell(
                                  onTap: () => onDeleteTap(index),
                                  child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.delete, color: Colors.red, size: 22)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}