class Lugar {
  final String nombre;
  final double latitud;
  final double longitud;

  Lugar({required this.nombre, required this.latitud, required this.longitud});

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'latitud': latitud,
    'longitud': longitud,
  };

  factory Lugar.fromJson(Map<String, dynamic> json) => Lugar(
    nombre: json['nombre'],
    latitud: json['latitud'],
    longitud: json['longitud'],
  );
}