import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';
import 'package:pedrapp/servicios/lugar_service.dart';

class HorarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GUARDAR O ACTUALIZAR BLOQUE EN LA NUBE ---
  Future<void> guardarBloque(BloqueHorario bloque) async {
    final idDispositivo = await LugarService.getDeviceId(); 

    await _db
        .collection('usuarios')
        .doc(idDispositivo) 
        .collection('horario_estudio')
        .doc(bloque.id)
        .set(bloque.toFirebase()); 
  }

  // --- BORRAR UN BLOQUE ---
  Future<void> borrarBloque(String idBloque) async {
    final idDispositivo = await LugarService.getDeviceId(); 

    await _db
        .collection('usuarios')
        .doc(idDispositivo) 
        .collection('horario_estudio')
        .doc(idBloque)
        .delete();
  }

  // --- DESCARGAR DATOS AL ABRIR LA APP ---
  Future<List<BloqueHorario>> cargarHorario() async {
    try {
      final idDispositivo = await LugarService.getDeviceId(); 

      var snapshot = await _db
          .collection('usuarios')
          .doc(idDispositivo) 
          .collection('horario_estudio')
          .get();

      List<BloqueHorario> listaCargada = [];
      
      for (var doc in snapshot.docs) {
        listaCargada.add(BloqueHorario.fromFirebase(doc.data()));
      }
      
      return listaCargada;

    } catch (e) {
      debugPrint("Error cargando horario: $e");
      return []; 
    }
  }
}