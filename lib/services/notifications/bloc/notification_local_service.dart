import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'uniescom_high',
    'UniEscom Notificaciones',
    description: 'Notificaciones de eventos y recordatorios',
    importance: Importance.max,
  );

  Future<void> init() async {
    // Configuración para Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS (Fernando: Agregue los ajustes para IOS)
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combinar ambas en InitializationSettings
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit, 
    );

    // Inicializa zonas horarias
    tz.initializeTimeZones();

    await _plugin.initialize(initSettings);

    // Crear canal en Android y solicitar permiso (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'uniescom_high',
      'UniEscom Notificaciones',
      channelDescription: 'Notificaciones de eventos y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleAt({
    required String title,
    required String body,
    required DateTime when,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'uniescom_high',
      'UniEscom Notificaciones',
      channelDescription: 'Notificaciones de eventos y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final scheduleId = id ?? (when.millisecondsSinceEpoch ~/ 1000);
    final tzWhen = tz.TZDateTime.from(when, tz.local);

    try {
      // Intento con programación exacta (puede requerir permiso especial en Android 12/13+)
      await _plugin.zonedSchedule(
        scheduleId,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback: programación inexacta (no requiere permiso de exact alarms)
      await _plugin.zonedSchedule(
        scheduleId,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
