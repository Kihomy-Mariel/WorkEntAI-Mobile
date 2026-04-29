import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'workentai_channel';
  static const _channelName = 'WorkEntAI Notificaciones';
  static const _channelDesc = 'Notificaciones de trámites y tareas';

  /// Inicializar Firebase + FCM + notificaciones locales
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Configurar notificaciones locales (para mostrar cuando app está en foreground)
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher_foreground');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // Crear canal Android (requerido para Android 8+)
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

    // Handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Pedir permiso de notificaciones
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Mensaje recibido con app en FOREGROUND → mostrar notificación local
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // App abierta desde notificación (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotifTap(message.data);
    });

    // App abierta desde notificación (app cerrada)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleNotifTap(initial.data);
    }
  }

  /// Obtener el FCM token del dispositivo y guardarlo en el backend
  static Future<void> registrarToken(String usuarioId, String authToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      // Guardar localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);

      // Enviar al backend
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/usuarios/$usuarioId/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      debugPrint('✅ FCM token registrado: ${fcmToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('⚠️ Error registrando FCM token: $e');
    }

    // Escuchar renovación del token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registrarToken(usuarioId, authToken);
    });
  }

  /// Mostrar notificación local (cuando app está en foreground)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    final title = notification.title ?? 'WorkEntAI';
    final body = notification.body ?? '';
    final tipo = message.data['tipo'] ?? 'SISTEMA';

    await _localNotif.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_foreground',
          color: const Color(0xFF2563EB),
          largeIcon: const DrawableResourceAndroidBitmap(
              '@drawable/ic_launcher_foreground'),
          styleInformation: BigTextStyleInformation(body),
          // Vibración y sonido
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
          // Categoría según tipo
          category: _getCategory(tipo),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotifTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotifTap(data);
      } catch (_) {}
    }
  }

  static void _handleNotifTap(Map<String, dynamic> data) {
    // Aquí puedes navegar a la pantalla correcta según el tipo
    final tipo = data['tipo'] ?? '';
    final referenciaId = data['referenciaId'] ?? '';
    debugPrint('Notificación tapeada: tipo=$tipo, id=$referenciaId');
    // La navegación se maneja en el AppNavigator
  }

  static AndroidNotificationCategory _getCategory(String tipo) {
    switch (tipo) {
      case 'TRAMITE_COMPLETADO':
        return AndroidNotificationCategory.status;
      case 'NUEVA_TAREA':
        return AndroidNotificationCategory.reminder;
      default:
        return AndroidNotificationCategory.message;
    }
  }
}
