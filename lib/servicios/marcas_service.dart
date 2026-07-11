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
        WriteBatch batch = _db.batch();
        
        for (var cat in plantillaInicial) {
          var docRef = _db
              .collection('usuarios')
              .doc(idDispositivo)
              .collection('marcas_oposicion')
              .doc(cat.id);
          batch.set(docRef, cat.toFirebase());
        }
        await batch.commit(); // Sube el paquete entero de golpe
        
        return plantillaInicial;
      }

      // EL USUARIO YA TIENE DATOS GUARDADOS
      List<CategoriaMarca> listaCargada = [];
      
      final Map<String, IconData> mapaIconos = {
        for (var item in plantillaInicial) item.id: item.icono
      };

      // Recorrer documento a documento lo que nos ha devuelto Firebase
      for (var doc in snapshot.docs) {
        var datos = doc.data(); // Extraer el diccionario (Map) con la info
        
        // recuperar el icono (ahora es una búsqueda instantánea)
        IconData iconoOriginal = mapaIconos[datos['id']] ?? Icons.star;

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