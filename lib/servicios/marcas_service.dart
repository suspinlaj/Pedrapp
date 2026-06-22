import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/marca.dart';
import 'package:pedrapp/servicios/lugar_service.dart'; 

class MarcasService {
  // leer y escribir en Firestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GUARDAR O ACTUALIZAR DATOS EN LA NUBE ---
  Future<void> guardarCategoria(CategoriaMarca categoria) async {
    final idDispositivo = await LugarService.getDeviceId(); 

    // guardar/sobreescribir el documento con el ID de la categoría.
    await _db
        .collection('usuarios')
        .doc(idDispositivo) 
        .collection('marcas_oposicion')
        .doc(categoria.id)
        .set(categoria.toFirebase()); 
  }

  // --- BORRAR UNA CATEGORÍA ENTERA ---
  Future<void> borrarCategoria(String idCategoria) async {
    final idDispositivo = await LugarService.getDeviceId(); 

    await _db
        .collection('usuarios')
        .doc(idDispositivo) 
        .collection('marcas_oposicion')
        .doc(idCategoria)
        .delete(); // para borrar de Firebase
  }

  // --- DESCARGAR DATOS AL ABRIR LA APP ---
  // Pide a Firebase las marcas guardadas.
  Future<List<CategoriaMarca>> cargarCategorias(List<CategoriaMarca> plantillaInicial) async {
    try {
      //  mismo ID que usa el mapa 
      final idDispositivo = await LugarService.getDeviceId(); 

      //  petición a Firebase
      var snapshot = await _db
          .collection('usuarios')
          .doc(idDispositivo) 
          .collection('marcas_oposicion')
          .get();

      // Si la carpeta está vacía, devolvemos la plantilla inicial y la guardamos en Firebase para que el usuario tenga algo con lo que empezar.
      if (snapshot.docs.isEmpty) {
        for (var cat in plantillaInicial) {
          await guardarCategoria(cat);
        }
        return plantillaInicial;
      }

      // EL USUARIO YA TIENE DATOS GUARDADOS
      List<CategoriaMarca> listaCargada = [];
      // Recorrer documento a documento lo que nos ha devuelto Firebase
      for (var doc in snapshot.docs) {
        var datos = doc.data(); // Extraer el diccionario (Map) con la info
        
        // recuperar el icono
        IconData iconoOriginal = plantillaInicial
            .firstWhere((element) => element.id == datos['id'], 
                      orElse: () => CategoriaMarca(id: 'err', nombre: '', icono: Icons.star, objetivo: 0.0))
            .icono;

        // Convertir texto de Firebase en un objeto de Flutter y lo añadir a la lista final
        listaCargada.add(CategoriaMarca.fromFirebase(datos, iconoOriginal));
      }
      
      return listaCargada;

    } catch (e) {
      print("Error cargando marcas: $e");
      return plantillaInicial; 
    }
  }
}