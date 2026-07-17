import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _notificationId = 1;

  static Future<void> inicializar() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _plugin.initialize(settings);

      // --- Pedir permisos automáticamente al usuario ---
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } 
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
  }

  static Future<void> mostrarEnProgreso(String titulo, String cuerpo) async {
    try {
      await _plugin.show(
        _notificationId,
        titulo,
        cuerpo,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pomodoro_channel',
            'Pomodoro',
            channelDescription: 'Notificaciones del temporizador',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.private,
            showWhen: false,
            onlyAlertOnce: true,
          ),
          iOS: DarwinNotificationDetails(presentAlert: false, presentBadge: false, presentSound: false),
        ),
      );
    } catch (_) {}
  }

  static Future<void> mostrarCompletado(String titulo, String cuerpo) async {
    try {
      await _plugin.show(
        _notificationId,
        titulo,
        cuerpo,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pomodoro_channel',
            'Pomodoro',
            channelDescription: 'Notificaciones del temporizador',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );
    } catch (_) {}
  }

  static Future<void> cancelar() async {
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }
}