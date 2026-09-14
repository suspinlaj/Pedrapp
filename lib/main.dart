import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedrapp/features/portada/portada_pantalla.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pedrapp/widgets/pomodoro/reloj_flotante_sistema.dart';
import 'firebase_options.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:app_links/app_links.dart';
import 'package:pedrapp/features/pomodoro/pomodoro_pantalla.dart';
import 'package:pedrapp/features/mapa/mapa_pantalla.dart'; // Tu ruta a la pantalla de Mapa

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  // Asegurar que Flutter está listo antes de arrancar nada
  WidgetsFlutterBinding.ensureInitialized();

  
  // Encender Firebase con archivo de configuración generado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _configurarDeepLinks();

  // Configurar los ajustes iniciales con el icono correcto
  const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // --- Solicitar permiso de notificaciones ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  // Arrancar app

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tuempresa.pedrapp.channel.audio',
    androidNotificationChannelName: 'Reproducción de Audio',
    androidNotificationOngoing: true,
  );

  runApp(const PedrApp());
}

void _configurarDeepLinks() async {
  final appLinks = AppLinks();
try {
    final Uri? initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _procesarRuta(initialUri);
    }
  } catch (e) {
    debugPrint('Error al obtener el enlace inicial: $e');
  }
  // Escuchar cuando la app se abre vía URL 'pedrapp://pomodoro'
  appLinks.uriLinkStream.listen((Uri uri) {
    _procesarRuta(uri);
  });
}

void _procesarRuta(Uri uri) {
  if (uri.scheme == 'pedrapp' && uri.host == 'pomodoro') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const PomodoroPantalla()),
      );
    });
  } else if (uri.scheme == 'pedrapp' && uri.host == 'mapa') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const MapaPantalla()),
      );
    });
  }
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