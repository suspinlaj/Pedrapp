import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static final http.Client _cliente = http.Client();

  static Future<List<dynamic>> buscar(String query) async {
    final String busquedaSegura = Uri.encodeQueryComponent(query);
    
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$busquedaSegura&format=json&limit=4&countrycodes=es');
    
    final response = await _cliente.get(
      url, 
      headers: {'User-Agent': 'Pedrapp/1.0 (tu_email@ejemplo.com)'}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}