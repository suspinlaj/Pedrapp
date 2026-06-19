import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/marca.dart';

// ¡IMPORTANTE! Importamos tu LugarService para poder usar su generador de ID
// (Ajusta la ruta si tu archivo de LugarService está en otra carpeta)
import 'package:pedrapp/servicios/lugar_service.dart'; 

class MarcasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Guardar o actualizar una categoría entera en la nube
  Future<void> guardarCategoria(CategoriaMarca categoria) async {
    // --- ¡AQUÍ ESTÁ LA MAGIA! ---
    // Usamos EXACTAMENTE el mismo ID que usa tu mapa
    final idDispositivo = await LugarService.getDeviceId(); 

    await _db
        .collection('usuarios')
        .doc(idDispositivo) // <-- ¡Ahora coincidirá con el del mapa!
        .collection('marcas_oposicion')
        .doc(categoria.id)
        .set(categoria.toFirebase());
  }

  // Descargar todas las marcas desde la nube al abrir la app
  Future<List<CategoriaMarca>> cargarCategorias(List<CategoriaMarca> plantillaInicial) async {
    try {
      // Usamos EXACTAMENTE el mismo ID que usa tu mapa
      final idDispositivo = await LugarService.getDeviceId(); 

      var snapshot = await _db
          .collection('usuarios')
          .doc(idDispositivo) 
          .collection('marcas_oposicion')
          .get();

      // Si el usuario no tiene nada guardado todavía, subimos la plantilla
      if (snapshot.docs.isEmpty) {
        for (var cat in plantillaInicial) {
          await guardarCategoria(cat);
        }
        return plantillaInicial;
      }

      // Si ya tiene datos, los cargamos
      List<CategoriaMarca> listaCargada = [];
      for (var doc in snapshot.docs) {
        var datos = doc.data();
        
        IconData iconoOriginal = plantillaInicial
            .firstWhere((element) => element.id == datos['id'], 
                       orElse: () => CategoriaMarca(id: 'err', nombre: '', icono: Icons.star, objetivo: 0.0))
            .icono;

        listaCargada.add(CategoriaMarca.fromFirebase(datos, iconoOriginal));
      }
      
      return listaCargada;
    } catch (e) {
      print("Error cargando marcas: $e");
      return plantillaInicial; 
    }
  }
}
// 5b4512d9-d6b9-4afc-bdfc-4fe8aa7b9bf5