import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedrapp/modelos/lugar.dart';

class LugarService {
  // Guarda la lista completa en la nube (Firestore)
  static Future<void> guardar(List<Lugar> lugares) async {
    // Obtener ID del usuario 
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Por si acaso no ha cargado aún

    // Convertir lista de objetos a un formato que Firebase entienda
    final listaTransformada = lugares.map((l) => l.toJson()).toList();

    // Guardar lista dentro de una colección llamada 'usuarios'
    // Cada móvil tendrá su propio documento usando su ID único (user.uid)
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set({'lugares_guardados': listaTransformada});
  }

  // Obtener la lista completa desde la nube (Firestore)
  static Future<List<Lugar>> obtener() async {
    // Obtener el ID del usuario
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Buscar su documento exacto a la bbdd y obtenerlo
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    // Si existe y tiene la lista guardada, sacarla
    if (snapshot.exists && snapshot.data()!.containsKey('lugares_guardados')) {
      final List<dynamic> listaData = snapshot.data()!['lugares_guardados'];
      
      // Volver a convertir datos en clase Lugar
      return listaData.map((item) => Lugar.fromJson(item)).toList();
    }
    
    // Devolvemos lista vacía si no hay nada guardado
    return [];
  }
}