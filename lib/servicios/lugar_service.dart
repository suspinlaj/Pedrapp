import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedrapp/modelos/lugar.dart';

class LugarService {
  static const String _key = 'lugares_guardados';

  // Guarda la lista completa
  static Future<void> guardar(List<Lugar> lugares) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(lugares.map((l) => l.toJson()).toList());
    await prefs.setString(_key, data);
  }

  // Obtiene la lista completa
  static Future<List<Lugar>> obtener() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    
    if (data == null) return [];
    
    final List<dynamic> listaJson = jsonDecode(data);
    return listaJson.map((item) => Lugar.fromJson(item)).toList();
  }
}