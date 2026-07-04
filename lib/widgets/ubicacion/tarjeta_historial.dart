import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedrapp/core/colores.dart';

class TarjetaHistorial extends StatelessWidget {
  final String miId;
  final String Function(Timestamp?) calcularTiempoFn;

  const TarjetaHistorial({
    super.key,
    required this.miId,
    required this.calcularTiempoFn,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ubicaciones_seguridad').snapshots(),
      builder: (context, snapshot) {
        String textoConexionDinamico = "Buscando conexión...";
        bool parejaActiva = true; // Por defecto asumimos que está compartiendo
        String nombrePareja = "tu pareja";
        
        if (snapshot.hasData) {
          textoConexionDinamico = "Tu pareja no ha iniciado el GPS hoy.";
          for (var doc in snapshot.data!.docs) {
            if (doc.id != miId) {
              nombrePareja = doc.id;
              var datos = doc.data() as Map<String, dynamic>;
              Timestamp? ultimaAct = datos['ultima_actualizacion'] as Timestamp?;
              
              // Leemos el nuevo estado de activación de Firebase (si no existe, asumimos false)
              parejaActiva = datos['activo'] ?? false;
              textoConexionDinamico = "Señal de $nombrePareja: ${calcularTiempoFn(ultimaAct)}";
            }
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bocadillito 1: El historial clásico que se ve SIEMPRE
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
            
            // --- NUEVO BOCADILLITO DE AVISO DESCONECTADO ---
            // Solo aparece si snapshot tiene datos y sabemos con certeza que la pareja no está activa
            if (snapshot.hasData && !parejaActiva) ...[
              const SizedBox(height: 6), // Separación entre ambos bocadillos
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
                    Icon(Icons.location_off, color: Colores.gris, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "$nombrePareja no está compartiendo su ubicación ahora mismo.", 
                        style: TextStyle(
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