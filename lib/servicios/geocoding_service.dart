import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static Future<List<dynamic>> buscar(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=4&countrycodes=es');
    final response = await http.get(
      url, 
      headers: {'User-Agent': 'Pedrapp/1.0 (tu_email@ejemplo.com)'}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}