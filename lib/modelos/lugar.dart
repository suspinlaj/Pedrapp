class Lugar {
  final String nombre;
  final String direccion; 
  final double latitud;
  final double longitud;

  Lugar({
    required this.nombre, 
    required this.direccion, 
    required this.latitud, 
    required this.longitud
  });

  // Lo añadimos al mapa para guardarlo
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'direccion': direccion, 
    'latitud': latitud,
    'longitud': longitud,
  };

  // Lo leemos del mapa al cargar
  factory Lugar.fromJson(Map<String, dynamic> json) => Lugar(
    nombre: json['nombre'],
    direccion: json['direccion'] ?? 'Sin dirección', 
    latitud: json['latitud'],
    longitud: json['longitud'],
  );
}