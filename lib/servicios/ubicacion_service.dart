import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _rastreador;

  // Inicia el seguimiento del GPS
  Future<void> iniciarSeguimiento(String miIdUsuario) async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // 1. Comprueba si el GPS del móvil está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El GPS está desactivado.');
    }

    // 2. Comprueba y pide los permisos necesarios
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Permisos de GPS denegados.');
      }
    }
    
    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Los permisos están denegados permanentemente. Ve a ajustes.');
    }

    // 3. Configuración inteligente para ahorrar batería y funcionar en segundo plano
    late LocationSettings configuracionUbicacion;

    if (Platform.isAndroid) {
      configuracionUbicacion = AndroidSettings(
        accuracy: LocationAccuracy.high, // Precisión alta pero no máxima para ahorrar batería
        distanceFilter: 50, // SOLO actualiza si se mueve 50 metros (ahorro de batería brutal)
        // Esto es la magia para que funcione con la pantalla bloqueada o Waze abierto
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Compartiendo ubicación por seguridad",
          notificationTitle: "Pedrapp GPS Activo",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      configuracionUbicacion = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        pauseLocationUpdatesAutomatically: true,
        allowBackgroundLocationUpdates: true, // Magia para iOS
      );
    } else {
      configuracionUbicacion = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }

    // 4. Empieza a escuchar el GPS y subirlo a Firebase automáticamente
    _rastreador = Geolocator.getPositionStream(locationSettings: configuracionUbicacion).listen(
      (Position posicion) {
        _subirUbicacionAFirebase(miIdUsuario, posicion);
      }
    );
  }

  // Sube las coordenadas a Firebase en la colección "ubicaciones_seguridad"
  Future<void> _subirUbicacionAFirebase(String id, Position posicion) async {
    await _db.collection('ubicaciones_seguridad').doc(id).set({
      'latitud': posicion.latitude,
      'longitud': posicion.longitude,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge hace que si no existe el doc, lo cree.
  }

  // Apaga el GPS cuando ya no queráis compartirlo para ahorrar batería
  void detenerSeguimiento() {
    _rastreador?.cancel();
    _rastreador = null;
  }
}