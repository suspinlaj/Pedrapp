import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedrapp/features/portada/portada_pantalla.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pedrapp/widgets/pomodoro/reloj_flotante_sistema.dart';
import 'firebase_options.dart';
import 'package:just_audio_background/just_audio_background.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // Asegurar que Flutter está listo antes de arrancar nada
  WidgetsFlutterBinding.ensureInitialized();

  // Encender Firebase con archivo de configuración generado
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar los ajustes iniciales con el icono correcto
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings();

  const WindowsInitializationSettings
  initializationSettingsWindows = WindowsInitializationSettings(
    appName: 'Pedrapp',
    appUserModelId:
        'com.tuempresa.pedrapp', // Identificador único de tu aplicación
    guid:
        '12345678-1234-1234-1234-123456789abc', // Un GUID de identificador único
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
    windows: initializationSettingsWindows,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // --- Solicitar permiso de notificaciones ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  // Arrancar app

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tuempresa.pedrapp.channel.audio',
    androidNotificationChannelName: 'Reproducción de Audio',
    androidNotificationOngoing: true,
  );

  runApp(const PedrApp());
}

class PedrApp extends StatelessWidget {
  const PedrApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Retornar la estructura base de la aplicación
    return MaterialApp(
      title: 'PedrApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PortadaPantalla(),
    );
  }
}

// Configurar el punto de entrada para el reloj flotante del pomodoro
@pragma("vm:entry-point")
void overlayMain() {
  // Asegurar la inicialización del motor en este proceso paralelo
  WidgetsFlutterBinding.ensureInitialized();

  // Arrancar lienzo gráfico exclusivo para la burbuja flotante
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RelojFlotanteSistema(),
    ),
  );
}
