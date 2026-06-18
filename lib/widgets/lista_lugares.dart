import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/lugar.dart';

class ListaLugares extends StatelessWidget {
  final List<Lugar> lugares; // Lista de datos a mostrar
  final Function(Lugar) onLugarTap; // Acción al tocar un lugar
  final Function(int) onDeleteTap; // Acción al borrar un lugar
  final Function(double, double) onNavigateTap; // Acción al navegar (Waze)

  const ListaLugares({
    super.key,
    required this.lugares,
    required this.onLugarTap,
    required this.onDeleteTap,
    required this.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Para decidir tamaños según el espacio real
        final bool isSmall = constraints.maxWidth < 250;

        // Define escalas de texto e iconos basados en el espacio detectado
        final double titleSize = isSmall ? 28 : 33;
        final double textSize = isSmall ? 14 : 18;
        final double iconSize = isSmall ? 20 : 22;

        return Column(
          children: [
            // --- TITULO ---
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                'Lugares',
                style: TextStyle(
                  color: Colores.gris,
                  fontFamily: 'Titulo',
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // --- LINEA DIVISORIA ---
            const Divider(
              color: Colores.rojo,
              thickness: 2.5,
            ),

            Expanded(
              child: lugares.isEmpty
                  ? const Center(
                      child: Text('No hay lugares guardados bobo'),
                    ) // Mensaje si la lista está vacía
                  : ListView.separated(
                      itemCount: lugares.length,

                      // Separador entre cada lugar de la lista
                      separatorBuilder: (_, _) => const Divider(
                        color: Colores.rojo,
                        indent: 20,
                        endIndent: 20,
                      ),

                      itemBuilder: (context, index) {
                        final lugar = lugares[index];

                        return InkWell(
                          onTap: () => onLugarTap(
                            lugar,
                          ), // Clic en el elemento para centrar mapa

                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- ICONO DE UBICACIÓN ---
                                const Icon(
                                  Icons.location_on,
                                  color: Colores.rojo,
                                  size: 24,
                                ),

                                const SizedBox(width: 5),

                                // --- NOMBRE Y DIRECCIÓN DEL LUGAR ---
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          // NOMBRE LUGAR
                                          Expanded(
                                            child: Transform.translate(
                                              offset: const Offset(0, -2), 
                                              child: Text(
                                                lugar.nombre,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: textSize,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Botón de navegación (Waze)
                                          InkWell(
                                            onTap: () => onNavigateTap(
                                              lugar.latitud,
                                              lugar.longitud,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.navigation,
                                                color: Colores.gris,
                                                size: iconSize,
                                              ),
                                            ),
                                          ),

                                          // Botón de borrar lugar
                                          InkWell(
                                            onTap: () =>
                                                onDeleteTap(index),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: iconSize,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // DIRECCION
                                      Text(
                                        lugar.direccion,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: textSize - 5,
                                        ),
                                      ),
                                    ],
                                  ),
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
      },
    );
  }
}