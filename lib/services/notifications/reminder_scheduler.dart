import 'dart:math';
import 'package:uni_escom/services/notifications/bloc/notification_local_service.dart';

class ReminderScheduler {
  ReminderScheduler._();
  static final instance = ReminderScheduler._();

  /// Muestra una notificación inmediata al registrarse a un evento
  Future<void> onEventRegistered({
    required String eventTitle,
  }) async {
    await LocalNotificationService.instance.show(
      title: 'Registro confirmado',
      body: 'Te registraste a "$eventTitle"',
    );
  }

  /// Programa recordatorios periódicos hasta la fecha del evento.
  /// - Intervalo por defecto: cada 3 días a las 9:00 AM hora local.
  /// - También programa un recordatorio el mismo día del evento (2 horas antes).
  Future<List<int>> scheduleEventReminders({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    int intervalDays = 3,
  }) async {
    final now = DateTime.now();
    final ids = <int>[];

    // Si el evento ya pasó, no programar.
    if (!eventDate.isAfter(now)) return ids;

    // Normaliza hora de recordatorios
    DateTime cursor = DateTime(now.year, now.month, now.day, 9);

    // Avanza cursor al siguiente punto si ya pasó la hora de hoy
    if (!cursor.isAfter(now)) {
      cursor = cursor.add(const Duration(days: 1));
    }

    // Programa cada N días a las 9:00 AM hasta 1 día antes del evento
    while (cursor.isBefore(eventDate.subtract(const Duration(days: 1)))) {
      final id = _notificationId(eventId, cursor);
      await LocalNotificationService.instance.scheduleAt(
        title: 'Recordatorio de evento',
        body: '"$eventTitle" será el ${_fmtDate(eventDate)}',
        when: cursor,
        id: id,
      );
      ids.add(id);
      cursor = cursor.add(Duration(days: intervalDays));
    }

    // Recordatorio el día del evento, 2 horas antes
    final dayOfReminder = eventDate.subtract(const Duration(hours: 2));
    if (dayOfReminder.isAfter(now)) {
      final id = _notificationId(eventId, dayOfReminder);
      await LocalNotificationService.instance.scheduleAt(
        title: '¡Hoy es el evento!',
        body: '"$eventTitle" comienza pronto',
        when: dayOfReminder,
        id: id,
      );
      ids.add(id);
    }

    return ids;
  }

  int _notificationId(String eventId, DateTime when) {
    // Genera un ID estable combinando eventId y fecha
    final seed = eventId.hashCode ^ when.millisecondsSinceEpoch;
    return (seed & 0x7FFFFFFF) % 2000000000; // limitar rango int32 positivo
  }

  String _fmtDate(DateTime dt) {
    // Formato simple: dd/MM/yyyy hh:mm
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Modo prueba: programa `count` recordatorios cada 2 minutos desde ahora.
  /// Útil para validar que la programación funciona en el dispositivo.
  Future<List<int>> scheduleTestRemindersEveryTwoMinutes({
    required String eventId,
    required String eventTitle,
    int count = 6,
  }) async {
    final now = DateTime.now();
    final ids = <int>[];

    for (int i = 1; i <= count; i++) {
      final when = now.add(Duration(minutes: 2 * i));
      final id = _notificationId(eventId, when);
      await LocalNotificationService.instance.scheduleAt(
        title: 'Recordatorio (prueba)',
        body: '"$eventTitle" — prueba en ${_fmtDate(when)}',
        when: when,
        id: id,
      );
      ids.add(id);
    }

    return ids;
  }
}
