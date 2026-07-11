import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedrapp/core/colores.dart';


class TarjetaHistorial extends StatefulWidget {
  final String miId; // Para saber quiénes somos y buscar al "otro"
  final String Function(Timestamp?) calcularTiempoFn; // Función que formatea la hora traída desde la pantalla principal

  const TarjetaHistorial({
    super.key,
    required this.miId,
    required this.calcularTiempoFn,
  });

  @override
  State<TarjetaHistorial> createState() => _TarjetaHistorialState();
}

class _TarjetaHistorialState extends State<TarjetaHistorial> {
  late final Stream<QuerySnapshot> _streamHistorial;

  @override
  void initState() {
    super.initState();
    // Abrimos el tubo de datos una sola vez al cargar la tarjeta
    _streamHistorial = FirebaseFirestore.instance.collection('ubicaciones_seguridad').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha en tiempo real a Firebase. 
    // Si el tiempo o el estado de la otra persona cambia, la tarjeta se actualiza 
    return StreamBuilder<QuerySnapshot>(
      stream: _streamHistorial, // Usamos la variable cacheada
      builder: (context, snapshot) {
        
        // Valor por defecto mientras carga o si no hay datos en Firebase
        String textoConexionDinamico = "Buscando conexión...";
        bool parejaActiva = true; 
        String nombrePareja = "tu pareja";
        
        if (snapshot.hasData) {
          textoConexionDinamico = "Tu pareja no ha iniciado el GPS hoy.";
          
          // Recorrer  documentos buscando el que no sea el dle usuario actual
          for (var doc in snapshot.data!.docs) {
            if (doc.id != widget.miId) {
              nombrePareja = doc.id;
              var datos = doc.data() as Map<String, dynamic>;
              Timestamp? ultimaAct = datos['ultima_actualizacion'] as Timestamp?;
              
              //  para saber si le dio al botón de apagar la otra persona
              parejaActiva = datos['activo'] ?? false;
              
              // Texto de historial conexion
              textoConexionDinamico = "Señal de $nombrePareja: ${widget.calcularTiempoFn(ultimaAct)}";
            }
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // BOCADILLO PRINCIPAL (El historial )
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colores.rojo, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, color: Colores.rojo, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      textoConexionDinamico, 
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87)
                    ),
                  ),
                ],
              ),
            ),
            
            // BOCADILLO SECUNDARIO (Aviso de GPS apagado)
            // Solo se dibuja si 'activo' es falso.
            if (snapshot.hasData && !parejaActiva) ...[
              const SizedBox(height: 6), 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colores.gris, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, color: Colores.gris, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      // FRASE NO ACTIVO
                      child: Text(
                        "$nombrePareja no está compartiendo su ubicación ahora mismo.", 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12, 
                          color: Colores.gris
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }
    );
  }
}