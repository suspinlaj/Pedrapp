import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _rastreador;
  DocumentReference? _miDocumentoCache;

  // Inicia el seguimiento del GPS
  Future<void> iniciarSeguimiento(String miIdUsuario) async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Comprueba si el GPS del móvil está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El GPS está desactivado.');
    }

    // Comprueba y pide los permisos necesarios
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

    // --- GUARDAMOS LA RUTA EN CACHÉ AL EMPEZAR ---
    _miDocumentoCache = _db.collection('ubicaciones_seguridad').doc(miIdUsuario);

    // Configuración para ahorrar batería y funcionar en segundo plano
    late LocationSettings configuracionUbicacion;

    if (Platform.isAndroid) {
      configuracionUbicacion = AndroidSettings(
        accuracy: LocationAccuracy.high, // Precisión alta pero no máxima para ahorrar batería
        distanceFilter: 50, // solo actualiza si se mueve 50 metros (ahorro de batería)
        //  para que funcione con la pantalla bloqueada o Waze abierto
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
        allowBackgroundLocationUpdates: true, 
      );
    } else {
      configuracionUbicacion = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }

    // Escuchar GPS y subirlo a Firebase automáticamente
    _rastreador = Geolocator.getPositionStream(locationSettings: configuracionUbicacion).listen(
      (Position posicion) {
        _subirUbicacionAFirebase(posicion); 
      }
    );
  }

  // Subir coordenadas a Firebase 
  Future<void> _subirUbicacionAFirebase(Position posicion) async {
    if (_miDocumentoCache == null) return; // Seguro por si falla algo

    await _miDocumentoCache!.set({
      'latitud': posicion.latitude,
      'longitud': posicion.longitude,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
      'activo': true, // Indica que está transmitiendo en vivo
    }, SetOptions(merge: true)); // merge hace que si no existe el doc, lo cree.
  }

  // Apaga el GPS cuando ya no se quiera compartir para ahorrar batería
  void detenerSeguimiento(String miIdUsuario) {
    _rastreador?.cancel();
    _rastreador = null;
    
    // Avisar a Firebase de que el usuario ha apagado su transmisión
    final docRef = _miDocumentoCache ?? _db.collection('ubicaciones_seguridad').doc(miIdUsuario);
    
    docRef.update({
      'activo': false,
    }).catchError((e) => debugPrint("Error al desactivar: $e"));
  }
}