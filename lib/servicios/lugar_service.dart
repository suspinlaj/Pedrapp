import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pedrapp/modelos/lugar.dart';

class LugarService {
  
  // Función interna para obtener el ID privado de este dispositivo
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('my_unique_device_id');
    
    // Si no existe, creamos uno nuevo (es la primera vez)
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('my_unique_device_id', deviceId);
    }
    return deviceId;
  }

  static Future<void> setDeviceId(String newId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('my_unique_device_id', newId);
}

  static Future<void> guardar(List<Lugar> lugares) async {
    final id = await getDeviceId(); // Obtenemos el ID privado
    final listaTransformada = lugares.map((l) => l.toJson()).toList();

    // Guardamos en la colección 'usuarios' pero en el documento de este ID
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(id) // <--- Aquí está la clave: cada móvil tiene su propio documento
        .set({'lugares_guardados': listaTransformada});
  }

  static Future<List<Lugar>> obtener() async {
    final id = await getDeviceId(); // Obtenemos el ID privado

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(id)
        .get();

    if (snapshot.exists && snapshot.data()!.containsKey('lugares_guardados')) {
      final List<dynamic> listaData = snapshot.data()!['lugares_guardados'];
      return listaData.map((item) => Lugar.fromJson(item)).toList();
    }
    return [];
  }
}